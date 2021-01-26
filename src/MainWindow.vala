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

public class Obliviate.MainWindow : Gtk.ApplicationWindow {
    private GLib.Settings settings;

    public MainWindow (Gtk.Application app) {
        Object (application: app);
    }

    construct {
        set_titlebar (get_header ());

        var main = new MainView ();
        add (main);

        set_geometry_hints (null, Gdk.Geometry () {
            min_width = 580,
            min_height = 520
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

    private Gtk.HeaderBar get_header () {
        var header = new Gtk.HeaderBar () {
            title = "Obliviate",
            has_subtitle = false,
            show_close_button = true
        };

        header.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        header.get_style_context ().add_class ("headerbar");

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
