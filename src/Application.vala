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

public class Obliviate.Application : Gtk.Application {
    private Obliviate.MainWindow window;

    public Application () {
        Object (
            application_id: "com.github.elfenware.obliviate"
        );
    }

    construct {
        Intl.setlocale (LocaleCategory.ALL, "");
        GLib.Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
        GLib.Intl.textdomain (GETTEXT_PACKAGE);
    }

    protected override void activate () {
        window = new MainWindow (this);
        window.show ();

        var gtk_settings = Gtk.Settings.get_default ();
        var granite_settings = Granite.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = (
            granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
        );

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = (
                granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
            );
        });

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/elfenware/obliviate/Application.css");
        Gtk.StyleContext.add_provider_for_display (
            Gdk.Display.get_default (),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
    }

    public static int main (string[] args) {
        var app = new Obliviate.Application ();
        return app.run (args);
    }
}
