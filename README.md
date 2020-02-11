# JuliaRegistry
Registry for my packages not published to the General registry.

```julia
pkg> registry add https://github.com/maxmouchet/JuliaRegistry.git
pkg> registry st
# Registry Status 
#  [23338594] General (https://github.com/JuliaRegistries/General.git)
#  [c7f9ddcf] maxmouchet (https://github.com/maxmouchet/JuliaRegistry.git)
```

```bash
julia tools/update.jl
```

**TODO**
- [ ] Compat file
