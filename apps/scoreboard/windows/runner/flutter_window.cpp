#include "flutter_window.h"

#include <commctrl.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <shellapi.h>
#include <shobjidl.h>

#include <optional>
#include <string>
#include <vector>

#include "flutter/generated_plugin_registrant.h"
#include "utils.h"

#pragma comment(lib, "comctl32.lib")

namespace {

using Channel = flutter::MethodChannel<flutter::EncodableValue>;

// Receives files dropped on the Flutter view; null while no window exists.
Channel* drop_channel = nullptr;

std::wstring Utf16FromUtf8(const std::string& text) {
  if (text.empty()) return std::wstring();
  const int length = MultiByteToWideChar(CP_UTF8, 0, text.data(),
                                         static_cast<int>(text.size()), nullptr, 0);
  std::wstring result(length, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()),
                      result.data(), length);
  return result;
}

// Shows the native open or save dialog; empty if cancelled. [pattern] is a
// semicolon separated filter such as "*.png;*.jpg".
std::optional<std::string> ChooseFile(HWND owner, bool save,
                                      const std::wstring& filter_name,
                                      const std::wstring& pattern,
                                      const std::wstring& default_name) {
  IFileDialog* dialog = nullptr;
  if (FAILED(CoCreateInstance(save ? CLSID_FileSaveDialog : CLSID_FileOpenDialog,
                              nullptr, CLSCTX_INPROC_SERVER,
                              IID_PPV_ARGS(&dialog)))) {
    return std::nullopt;
  }
  const COMDLG_FILTERSPEC filters[] = {{filter_name.c_str(), pattern.c_str()},
                                       {L"All files", L"*.*"}};
  dialog->SetFileTypes(2, filters);
  if (save) {
    const auto dot = pattern.find(L'.');
    const auto end = pattern.find(L';');
    if (dot != std::wstring::npos) {
      dialog->SetDefaultExtension(pattern.substr(dot + 1, end - dot - 1).c_str());
    }
    dialog->SetFileName(default_name.c_str());
  }
  DWORD options = 0;
  dialog->GetOptions(&options);
  dialog->SetOptions(options | FOS_FORCEFILESYSTEM |
                     (save ? FOS_OVERWRITEPROMPT : FOS_FILEMUSTEXIST));

  std::optional<std::string> path;
  if (SUCCEEDED(dialog->Show(owner))) {
    IShellItem* item = nullptr;
    if (SUCCEEDED(dialog->GetResult(&item))) {
      PWSTR name = nullptr;
      if (SUCCEEDED(item->GetDisplayName(SIGDN_FILESYSPATH, &name))) {
        path = Utf8FromUtf16(name);
        CoTaskMemFree(name);
      }
      item->Release();
    }
  }
  dialog->Release();
  return path;
}

// Forwards dropped files with the drop position (physical pixels).
LRESULT CALLBACK DropProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam,
                          UINT_PTR, DWORD_PTR) {
  if (message != WM_DROPFILES) {
    return DefSubclassProc(hwnd, message, wparam, lparam);
  }
  HDROP drop = reinterpret_cast<HDROP>(wparam);
  POINT point = {0, 0};
  DragQueryPoint(drop, &point);
  flutter::EncodableList files;
  const UINT count = DragQueryFileW(drop, 0xFFFFFFFF, nullptr, 0);
  for (UINT i = 0; i < count; ++i) {
    wchar_t buffer[MAX_PATH * 4];
    if (DragQueryFileW(drop, i, buffer, MAX_PATH * 4) > 0) {
      files.push_back(flutter::EncodableValue(Utf8FromUtf16(buffer)));
    }
  }
  DragFinish(drop);
  if (drop_channel != nullptr) {
    drop_channel->InvokeMethod(
        "filesDropped",
        std::make_unique<flutter::EncodableValue>(flutter::EncodableMap{
            {flutter::EncodableValue("files"), flutter::EncodableValue(files)},
            {flutter::EncodableValue("x"),
             flutter::EncodableValue(static_cast<int>(point.x))},
            {flutter::EncodableValue("y"),
             flutter::EncodableValue(static_cast<int>(point.y))}}));
  }
  return 0;
}

BOOL CALLBACK CollectMonitor(HMONITOR monitor, HDC, LPRECT, LPARAM data) {
  reinterpret_cast<std::vector<HMONITOR>*>(data)->push_back(monitor);
  return TRUE;
}

std::vector<HMONITOR> Monitors() {
  std::vector<HMONITOR> list;
  EnumDisplayMonitors(nullptr, nullptr, CollectMonitor,
                      reinterpret_cast<LPARAM>(&list));
  return list;
}

struct SavedWindow {
  bool fullscreen = false;
  LONG style = 0;
  WINDOWPLACEMENT placement = {sizeof(WINDOWPLACEMENT)};
};
SavedWindow saved;

// Borderless fullscreen on |monitor|, or restores the previous window.
void ApplyFullScreen(HWND hwnd, bool fullscreen, HMONITOR monitor) {
  if (fullscreen) {
    if (!saved.fullscreen) {
      saved.style = GetWindowLong(hwnd, GWL_STYLE);
      GetWindowPlacement(hwnd, &saved.placement);
    }
    MONITORINFO mi = {sizeof(MONITORINFO)};
    GetMonitorInfo(monitor, &mi);
    ShowWindow(hwnd, SW_RESTORE);
    SetWindowLong(hwnd, GWL_STYLE, saved.style & ~WS_OVERLAPPEDWINDOW);
    SetWindowPos(hwnd, HWND_TOP, mi.rcMonitor.left, mi.rcMonitor.top,
                 mi.rcMonitor.right - mi.rcMonitor.left,
                 mi.rcMonitor.bottom - mi.rcMonitor.top,
                 SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
    saved.fullscreen = true;
  } else if (saved.fullscreen) {
    SetWindowLong(hwnd, GWL_STYLE, saved.style);
    SetWindowPlacement(hwnd, &saved.placement);
    SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER |
                     SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
    saved.fullscreen = false;
  }
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Window control channel (no plugin needed): monitor count, fullscreen on a
  // chosen monitor.
  window_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "scoreboard/window",
          &flutter::StandardMethodCodec::GetInstance());
  window_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        HWND hwnd = GetHandle();
        const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
        auto arg_int = [&](const char* key, int fallback) {
          if (args) {
            auto it = args->find(flutter::EncodableValue(key));
            if (it != args->end()) {
              if (auto* v = std::get_if<int32_t>(&it->second)) return (int)*v;
            }
          }
          return fallback;
        };
        auto arg_bool = [&](const char* key, bool fallback) {
          if (args) {
            auto it = args->find(flutter::EncodableValue(key));
            if (it != args->end()) {
              if (auto* v = std::get_if<bool>(&it->second)) return *v;
            }
          }
          return fallback;
        };
        auto arg_text = [&](const char* key) {
          if (args) {
            auto it = args->find(flutter::EncodableValue(key));
            if (it != args->end()) {
              if (auto* v = std::get_if<std::string>(&it->second)) {
                return Utf16FromUtf8(*v);
              }
            }
          }
          return std::wstring();
        };
        if (call.method_name() == "monitorCount") {
          result->Success(flutter::EncodableValue((int)Monitors().size()));
        } else if (call.method_name() == "isFullScreen") {
          result->Success(flutter::EncodableValue(saved.fullscreen));
        } else if (call.method_name() == "setFullScreen") {
          const auto monitors = Monitors();
          int index = arg_int("monitor", -1);
          HMONITOR target =
              (index >= 0 && index < (int)monitors.size())
                  ? monitors[index]
                  : MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
          ApplyFullScreen(hwnd, arg_bool("value", true), target);
          result->Success();
        } else if (call.method_name() == "setTitle") {
          SetWindowTextW(hwnd, arg_text("title").c_str());
          result->Success();
        } else if (call.method_name() == "chooseFile") {
          const auto path =
              ChooseFile(hwnd, arg_bool("save", false), arg_text("filterName"),
                         arg_text("pattern"), arg_text("defaultName"));
          result->Success(path ? flutter::EncodableValue(*path)
                               : flutter::EncodableValue());
        } else {
          result->NotImplemented();
        }
      });

  drop_channel = window_channel_.get();
  HWND view_window = flutter_controller_->view()->GetNativeWindow();
  DragAcceptFiles(view_window, TRUE);
  SetWindowSubclass(view_window, DropProc, 1, 0);

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  drop_channel = nullptr;
  window_channel_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
