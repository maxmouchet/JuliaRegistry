import LibGit2: checkout!, clone, peel, tag_list, CloneOptions, GitCommit, GitHash, GitObject, GitTree
import Pkg: TOML

Packages = Dict()

# TODO: Git pull to make sure registry is up to date

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

    Packages[Package["uuid"]] = Dict(
        "name" => Package["name"],
        "path" => Package["name"]
    )

    for tag in tag_list(repo)
        obj = GitObject(repo, tag)
        obj_hash = string(GitHash(obj))

        tree = peel(obj)
        tree_hash = string(GitHash(tree))

        checkout!(repo, obj_hash)

        project = TOML.parsefile(joinpath(dir, "Project.toml"))
        version = project["version"]

        @info "$(project["name"]) v$(version) => $(tree_hash)"

        Deps[version] = project["deps"]

        Versions[version] = Dict(
            "git-tree-sha1" => string(GitHash(tree_hash))
        )
    end

    rm(dir, recursive=true)

    # TODO: Sort keys
    mkpath(Package["name"])
    TOML.print(open(joinpath(Package["name"], "Deps.toml"), "w"), Deps)
    TOML.print(open(joinpath(Package["name"], "Package.toml"), "w"), Package)
    TOML.print(open(joinpath(Package["name"], "Versions.toml"), "w"), Versions)
end

registry = TOML.parsefile("Registry.toml")
registry["packages"] = Packages
TOML.print(open("Registry.toml", "w"), registry)