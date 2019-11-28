import LibGit2: checkout!, clone, peel, tag_list, CloneOptions, GitCommit, GitHash, GitObject, GitTree
import Pkg: TOML

Packages = Dict()
PkgsDir = "packages/"
ActivePkgs = String[]

for url in readlines("tools/packages.txt")
    startswith(url, "#") && continue

    dir = mktempdir()
    @info "Cloning $(url) to $(dir)..."
    repo = clone(url, dir)

    Deps = Dict()
    Versions = Dict()

    project = TOML.parsefile(joinpath(dir, "Project.toml"))

    Package = Dict(
        "name" => project["name"],
        "uuid" => project["uuid"],
        "repo" => url
    )

    pkgpath = joinpath(PkgsDir, Package["name"])
    push!(ActivePkgs, Package["name"])

    Packages[Package["uuid"]] = Dict(
        "name" => Package["name"],
        "path" => pkgpath
    )

    for tag in tag_list(repo)
        obj = GitObject(repo, tag)
        obj_hash = string(GitHash(obj))

        tree = peel(obj)
        tree_hash = string(GitHash(tree))

        checkout!(repo, obj_hash)

        project = TOML.parsefile(joinpath(dir, "Project.toml"))
        version = project["version"]
	if match(r"^[\d\.]+$", version) === nothing
	    @info "Skipping (invalid) version $(version)"
            continue
        end

        @info "$(project["name"]) v$(version) => $(tree_hash)"

        Deps[version] = project["deps"]

        Versions[version] = Dict(
            "git-tree-sha1" => string(GitHash(tree_hash))
        )
    end

    rm(dir, recursive = true)

    mkpath(pkgpath)

    TOML.print(open(joinpath(pkgpath, "Deps.toml"), "w"), Deps, sorted = true)
    TOML.print(open(joinpath(pkgpath, "Package.toml"), "w"), Package, sorted = true)
    TOML.print(open(joinpath(pkgpath, "Versions.toml"), "w"), Versions, sorted = true)
end

# Cleanup packages not present in packages.txt
for pkg in readdir(PkgsDir)
    if !(pkg in ActivePkgs)
        @info "Removing $pkg"
        rm(joinpath(PkgsDir, pkg), recursive = true)
    end
end

registry = TOML.parsefile("Registry.toml")
registry["packages"] = Packages
TOML.print(open("Registry.toml", "w"), registry)
