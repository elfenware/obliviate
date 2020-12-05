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

public class Obliviate.Crypto : GLib.Object {

    public static string derive_password (string cipher_key, string salt) {
        var keybuffer = new uint8[16];

        const char[] ALLOWED_CHARS = {
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
            'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
            'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
            'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
            'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
            '!', '#', '$', '%', '&', '(', ')', '*', '+', '-', ';', '<', '=',
            '>', '?', '@', '^', '_', '`', '{', '|', '}', '~'
        };

        // TODO: handle error
        var error = GCrypt.KeyDerivation.derive (
            cipher_key.data,
            GCrypt.KeyDerivation.Algorithm.PBKDF2,
            GCrypt.Hash.Algorithm.SHA256,
            salt.data,
            10000,
            keybuffer
        );

        // keybuffer will have values ranging from 0 to 255.
        // This is the mapping of those integers to ALLOWED_CHARS.
        var derived_characters = new StringBuilder.sized (keybuffer.length);

        for (ushort index = 0; index < keybuffer.length; index++) {
            var character = ALLOWED_CHARS[keybuffer[index] % ALLOWED_CHARS.length];
            derived_characters.append_c (character);
        }

        return derived_characters.str;
    }
}
