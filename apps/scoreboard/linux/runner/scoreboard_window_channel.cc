#include "scoreboard_window_channel.h"

#include <string.h>

namespace {

constexpr char kChannelDataKey[] = "scoreboard-window-channel";

FlValue* get_argument(FlValue* arguments, const gchar* name) {
  if (arguments == nullptr || fl_value_get_type(arguments) != FL_VALUE_TYPE_MAP) {
    return nullptr;
  }
  return fl_value_lookup_string(arguments, name);
}

gint64 get_int_argument(FlValue* arguments,
                        const gchar* name,
                        gint64 fallback) {
  FlValue* value = get_argument(arguments, name);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_INT
             ? fl_value_get_int(value)
             : fallback;
}

gboolean get_bool_argument(FlValue* arguments,
                           const gchar* name,
                           gboolean fallback) {
  FlValue* value = get_argument(arguments, name);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_BOOL
             ? fl_value_get_bool(value)
             : fallback;
}

const gchar* get_string_argument(FlValue* arguments,
                                 const gchar* name,
                                 const gchar* fallback) {
  FlValue* value = get_argument(arguments, name);
  return value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_STRING
             ? fl_value_get_string(value)
             : fallback;
}

void respond_success(FlMethodCall* call, FlValue* value) {
  g_autoptr(FlValue) result = value;
  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond_success(call, result, &error)) {
    g_warning("Failed to respond to window method: %s", error->message);
  }
}

FlValue* choose_file(GtkWindow* parent, FlValue* arguments) {
  const gboolean save = get_bool_argument(arguments, "save", FALSE);
  const gchar* filter_name =
      get_string_argument(arguments, "filterName", "Files");
  const gchar* pattern = get_string_argument(arguments, "pattern", "*");
  const gchar* default_name =
      get_string_argument(arguments, "defaultName", "");

  GtkWidget* dialog = gtk_file_chooser_dialog_new(
      save ? "Save file" : "Open file", parent,
      save ? GTK_FILE_CHOOSER_ACTION_SAVE : GTK_FILE_CHOOSER_ACTION_OPEN,
      "_Cancel", GTK_RESPONSE_CANCEL, save ? "_Save" : "_Open",
      GTK_RESPONSE_ACCEPT, nullptr);
  GtkFileChooser* chooser = GTK_FILE_CHOOSER(dialog);
  if (save) {
    gtk_file_chooser_set_do_overwrite_confirmation(chooser, TRUE);
    if (*default_name != '\0') {
      gtk_file_chooser_set_current_name(chooser, default_name);
    }
  }

  GtkFileFilter* filter = gtk_file_filter_new();
  gtk_file_filter_set_name(filter, filter_name);
  gchar** patterns = g_strsplit(pattern, ";", -1);
  for (gchar** item = patterns; item != nullptr && *item != nullptr; ++item) {
    gchar* trimmed = g_strstrip(*item);
    if (*trimmed != '\0') {
      gtk_file_filter_add_pattern(filter, trimmed);
    }
  }
  g_strfreev(patterns);
  gtk_file_chooser_add_filter(chooser, filter);
  g_object_unref(filter);

  gchar* path = nullptr;
  if (gtk_dialog_run(GTK_DIALOG(dialog)) == GTK_RESPONSE_ACCEPT) {
    path = gtk_file_chooser_get_filename(chooser);
  }
  gtk_widget_destroy(dialog);

  FlValue* result =
      path == nullptr ? fl_value_new_null() : fl_value_new_string(path);
  g_free(path);
  return result;
}

void handle_method_call(FlMethodChannel*,
                        FlMethodCall* call,
                        gpointer user_data) {
  GtkWindow* window = GTK_WINDOW(user_data);
  FlValue* arguments = fl_method_call_get_args(call);
  const gchar* method = fl_method_call_get_name(call);

  if (strcmp(method, "monitorCount") == 0) {
    GdkDisplay* display = gdk_display_get_default();
    respond_success(
        call, fl_value_new_int(display == nullptr
                                   ? 0
                                   : gdk_display_get_n_monitors(display)));
  } else if (strcmp(method, "isFullScreen") == 0) {
    GdkWindow* native_window = gtk_widget_get_window(GTK_WIDGET(window));
    const gboolean full_screen =
        native_window != nullptr &&
        (gdk_window_get_state(native_window) & GDK_WINDOW_STATE_FULLSCREEN) !=
            0;
    respond_success(call, fl_value_new_bool(full_screen));
  } else if (strcmp(method, "setFullScreen") == 0) {
    const gboolean full_screen =
        get_bool_argument(arguments, "value", TRUE);
    if (!full_screen) {
      gtk_window_unfullscreen(window);
    } else {
      const gint64 monitor = get_int_argument(arguments, "monitor", -1);
      GdkDisplay* display = gdk_display_get_default();
      const gint monitor_count =
          display == nullptr ? 0 : gdk_display_get_n_monitors(display);
      if (display != nullptr && monitor >= 0 && monitor < monitor_count) {
        gtk_window_fullscreen_on_monitor(
            window, gdk_display_get_default_screen(display),
            static_cast<gint>(monitor));
      } else {
        gtk_window_fullscreen(window);
      }
    }
    respond_success(call, nullptr);
  } else if (strcmp(method, "setTitle") == 0) {
    gtk_window_set_title(
        window, get_string_argument(arguments, "title", "Scoreboard"));
    respond_success(call, nullptr);
  } else if (strcmp(method, "chooseFile") == 0) {
    respond_success(call, choose_file(window, arguments));
  } else {
    g_autoptr(GError) error = nullptr;
    if (!fl_method_call_respond_not_implemented(call, &error)) {
      g_warning("Failed to respond to unsupported window method: %s",
                error->message);
    }
  }
}

void handle_files_dropped(GtkWidget* widget,
                          GdkDragContext* context,
                          gint x,
                          gint y,
                          GtkSelectionData* data,
                          guint,
                          guint time) {
  FlMethodChannel* channel = FL_METHOD_CHANNEL(
      g_object_get_data(G_OBJECT(widget), kChannelDataKey));
  gchar** uris = gtk_selection_data_get_uris(data);
  g_autoptr(FlValue) files = fl_value_new_list();
  for (gchar** item = uris; item != nullptr && *item != nullptr; ++item) {
    g_autoptr(GError) error = nullptr;
    gchar* path = g_filename_from_uri(*item, nullptr, &error);
    if (path != nullptr) {
      fl_value_append_take(files, fl_value_new_string(path));
      g_free(path);
    }
  }
  g_strfreev(uris);

  const gboolean has_files = fl_value_get_length(files) > 0;
  if (channel != nullptr && has_files) {
    g_autoptr(FlValue) arguments = fl_value_new_map();
    const gint scale = gtk_widget_get_scale_factor(widget);
    fl_value_set_string_take(arguments, "files", g_steal_pointer(&files));
    fl_value_set_string_take(
        arguments, "x", fl_value_new_int(static_cast<gint64>(x) * scale));
    fl_value_set_string_take(
        arguments, "y", fl_value_new_int(static_cast<gint64>(y) * scale));
    fl_method_channel_invoke_method(channel, "filesDropped", arguments, nullptr,
                                    nullptr, nullptr);
  }
  gtk_drag_finish(context, has_files, FALSE, time);
}

}  // namespace

void scoreboard_window_channel_register(FlView* view) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "scoreboard/window", FL_METHOD_CODEC(codec));
  GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(GTK_WIDGET(view)));
  fl_method_channel_set_method_call_handler(channel, handle_method_call, window,
                                            nullptr);
  g_object_set_data_full(G_OBJECT(view), kChannelDataKey, channel,
                         g_object_unref);

  const GtkTargetEntry targets[] = {
      {const_cast<gchar*>("text/uri-list"), 0, 0},
  };
  gtk_drag_dest_set(GTK_WIDGET(view), GTK_DEST_DEFAULT_ALL, targets,
                    G_N_ELEMENTS(targets), GDK_ACTION_COPY);
  g_signal_connect(view, "drag-data-received", G_CALLBACK(handle_files_dropped),
                   nullptr);
}
