;+
;  ROIseries_2D: Class responsible for handling ROIseries objects that have been reduced to two dimensions.
;  Copyright (C) 2017 Niklas Keck
;
;  This file is part of ROIseries.
;
;  ROIseries is free software: you can redistribute it and/or modify
;  it under the terms of the GNU Affero General Public License as published by
;  the Free Software Foundation, either version 3 of the License, or
;  (at your option) any later version.
;
;  ROIseries is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU Affero General Public License for more details.
;
;  You should have received a copy of the GNU Affero General Public License
;  along with ROIseries.  If not, see <http://www.gnu.org/licenses/>.
;-
FUNCTION ROIseries_2D :: spatial_mixer,statistics_type
  COMPILE_OPT idl2, HIDDEN
  ON_ERROR,self.on_error

  RS1D = ROIseries_1D()
  RS1D.no_save = self.no_save
  RS1D.parents = self.parents
  RS1D.history = self.history
  RS1D.DB = self.db
  RS1D.id = self.id
  RS1D.time = self.time
  RS1D.class = self.class
  RS1D.unit = self.unit
  result = RS2D_SPATIAL_MIXER(self,statistics_type)
  RS1D.data = result[0]
  RS1D.time = result[1]
  RS1D.savetodb,"spatial_mixer_"+statistics_type

  RETURN,RS1D
END

PRO ROIseries_2D__define,void
  COMPILE_OPT idl2, HIDDEN
  void={ROIseries_2D,inherits ROIseries}
END