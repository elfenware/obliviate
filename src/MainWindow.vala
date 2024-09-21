/*
 *  Copyright (C) 2020 Darshak Parikh
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *  Authored by: Darshak Parikh <darshak@protonmail.com>
 *
 */

public class Obliviate.MainWindow : Adw.ApplicationWindow {
    private GLib.Settings settings;

    public MainWindow (Gtk.Application app) {
        Object (application: app);
    }

    construct {
        Hdy.init ();
        var header = get_header ();

        var main = new MainView ();

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.add (header);
        box.add (main);
        add (box);

        set_geometry_hints (null, Gdk.Geometry () {
            min_width = 440,
            min_height = 280
        }, Gdk.WindowHints.MIN_SIZE);

        settings = new GLib.Settings ("com.github.elfenware.obliviate.state");

        int default_x = settings.get_int ("window-x");
        int default_y = settings.get_int ("window-y");

        if (default_x != -1 && default_y != -1) {
            move (default_x, default_y);
        }

        resize (settings.get_int ("window-width"), settings.get_int ("window-height"));

        show_all ();

        delete_event.connect (e => {
            return before_destroy ();
        });
    }

    private Adw.HeaderBar get_header () {
        var header = new Adw.HeaderBar () {
            title = "Obliviate",
            has_subtitle = false,
            show_close_button = true
        };

        header.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        header.get_style_context ().add_class ("headerbar");

        var help_btn = new Gtk.Button.from_icon_name ("help-contents") {
            tooltip_text = _("Help and FAQ")
        };

        help_btn.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("https://github.com/elfenware/obliviate/wiki/Help-and-FAQ", null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        });

        header.pack_end (help_btn);

        return header;
    }

    private bool before_destroy () {
        int x, y, width, height;

        get_position (out x, out y);
        get_size (out width, out height);

        settings.set_int ("window-x", x);
        settings.set_int ("window-y", y);
        settings.set_int ("window-width", width);
        settings.set_int ("window-height", height);

        return false;
    }
}
