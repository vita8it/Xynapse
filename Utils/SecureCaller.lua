local SecureCaller = {} do
    SecureCaller.Layers = 2
end

SecureCaller.Template = (function()
    local self = SecureCaller
    
    local Lines = {
        "return function(__renv, __func, ...)",
        "\tsetfenv(0, __renv)",
        `\tlocal function l{self.Layers}(...) return __func(...) end`,
    }
    
    for Count = self.Layers - 1, 1, -1 do
        Lines[ #Lines + 1 ] = `\tlocal function l{Count}(...) return l{Count + 1}(...) end`
    end

    Lines[ #Lines + 1 ] = "\treturn l1(...)"
    Lines[ #Lines + 1 ] = "end"
    
    return table.concat(Lines, "\n")
end)()

return setmetatable({}, {
    __call = function(_, Function, Mask, ...)
        assert(type(Function) == "function", `invalid argument #1 to 'secure_call' (function expected, got {typeof(Function)})`)
        assert(debug.info(Function, "s") ~= "[C]", "invalid argument #1 to 'secure_call' (Luau closure expected, got C closure)")
        assert(typeof(Mask) == "Instance" and Mask:IsA("LuaSourceContainer"), `invalid argument #2 to 'secure_call' (LuaSourceContainer expected, got {typeof(mask)})`)
        
        local Level = getthreadidentity()
        local Runtime = getrenv()
        
        local Path = Mask:GetFullName()
        local Success, Environtment = pcall(getsenv, Mask)
        
        if not Success or type(Environtment) ~= "table" then
            Environtment = setmetatable({ script = Mask }, {
                __index = Runtime,
                __newindex = Runtime
            })
        end
        
        local Loader, Error = loadstring(SecureCaller.Template, `={Path}`) do
            setfenv(Loader, Environtment)
        end
        
        local Sentinel = Loader()
        local Snapshot = getupvalues(Function)
        
        for Index = 1, #Snapshot do
            local Value = Snapshot[Index]
            if typeof(Value) == "Instance" and Value:IsA("LuaSourceContainer") then
                setupvalue(Function, Index, Mask)
            end
        end
        
        local Response, Coroutine = nil, coroutine.create(Sentinel)
        local Args = table.pack(Runtime, Function, ...)
        
        setthreadidentity(2) do
            while true do
                local Result = table.pack(
                    coroutine.resume(Coroutine, unpack(Args, 1, Args.n))
                )
                
                if not Result[1] then
                    Error = Result[2];break
                end
                
                if coroutine.status(Coroutine) == "dead" then
                    Response = table.pack(
                        unpack(Result, 2, Result.n)
                    );break
                end
                
                Args = table.pack(
                    coroutine.yield(unpack(Result, 2, Result.n))
                )
            end
        end setthreadidentity(Level)
        
        for Index = 1, #Snapshot do
            setupvalue(Function, Index, Snapshot[ Index ])
        end
        
        if Error then error(Error, 2) end
        return unpack(Response, 1, Response.n)
    end,
})
