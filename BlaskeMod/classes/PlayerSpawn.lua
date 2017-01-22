PlayerSpawn = {
    X = 0,
    Y = 0,
    SurfaceIndex = 1,
    new = function(self, obj)
        obj = obj or { }
        setmetatable(obj, self)
        self.__index = self
        return obj
    end
}