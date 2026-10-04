# SPDX-License-Identifier: LGPL-2.1-or-later

# ***************************************************************************
# *   Copyright (c) 2026 FreeCAD Project Association                        *
# *                                                                         *
# *   This file is part of the FreeCAD CAx development system.              *
# *                                                                         *
# *   FreeCAD is free software; you can redistribute it and/or modify it    *
# *   under the terms of the GNU Lesser General Public License (LGPL)       *
# *   as published by the Free Software Foundation; either version 2.1 of   *
# *   the License, or (at your option) any later version.                   *
# *                                                                         *
# *   FreeCAD is distributed in the hope that it will be useful, but        *
# *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
# *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU      *
# *   Lesser General Public License for more details.                       *
# *                                                                         *
# *   You should have received a copy of the GNU Lesser General Public      *
# *   License along with FreeCAD. If not, see                               *
# *   <https://www.gnu.org/licenses/>.                                      *
# *                                                                         *
# ***************************************************************************

"""Unit tests for the Draft Layer object, GUI only."""

import Draft
import FreeCAD as App

from drafttests import test_base


class DraftGuiLayer(test_base.DraftTestCaseDoc):
    """Tests for the view properties that a layer passes on to its objects."""

    def _make_scene(self):
        """Create a rectangle, a Part::Mirroring of it and a red dashed layer."""
        rect = Draft.make_rectangle(10, 5)
        mir = Draft.mirror(rect, App.Vector(0, 0, 0), App.Vector(0, 10, 0))
        layer = Draft.make_layer("Test", line_color=(1.0, 0.0, 0.0), draw_style="Dashed")
        self.doc.recompute()
        return rect, mir, layer

    def _rgb(self, col):
        return tuple(round(c, 2) for c in col[:3])

    def test_mirror_source_takes_layer_style(self):
        """Dropping a mirror on a layer also styles the source nested under it."""
        rect, mir, layer = self._make_scene()
        layer.ViewObject.Proxy.dropObject(layer.ViewObject, mir)
        self.assertEqual(layer.Group, [mir])
        for obj in (mir, rect):
            self.assertEqual(self._rgb(obj.ViewObject.LineColor), (1.0, 0.0, 0.0), obj.Name)
            self.assertEqual(obj.ViewObject.DrawStyle, "Dashed", obj.Name)

    def test_mirror_source_follows_layer_change(self):
        """A later change of the layer reaches the source of a mirror in the layer."""
        rect, mir, layer = self._make_scene()
        layer.ViewObject.Proxy.dropObject(layer.ViewObject, mir)
        layer.ViewObject.LineColor = (0.0, 0.0, 1.0)
        self.assertEqual(self._rgb(rect.ViewObject.LineColor), (0.0, 0.0, 1.0))

    def test_mirror_source_visibility_unchanged(self):
        """The visibility of the source of a mirror is not changed by the layer."""
        rect, mir, layer = self._make_scene()
        rect.ViewObject.Visibility = False
        layer.ViewObject.Proxy.dropObject(layer.ViewObject, mir)
        self.assertFalse(rect.ViewObject.Visibility)

    def test_mirror_source_in_other_layer_unchanged(self):
        """A source that is in a layer itself keeps the style of that layer."""
        rect, mir, layer = self._make_scene()
        other = Draft.make_layer("Other", line_color=(0.0, 1.0, 0.0))
        other.Proxy.addObject(other, rect)
        layer.ViewObject.Proxy.dropObject(layer.ViewObject, mir)
        self.assertEqual(self._rgb(rect.ViewObject.LineColor), (0.0, 1.0, 0.0))
        self.assertEqual(rect.ViewObject.DrawStyle, "Solid")
