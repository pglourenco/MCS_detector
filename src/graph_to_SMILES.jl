# ==============================================================================
# MODULE: GRAPH TO SMILES CONVERTER
# ==============================================================================

function graph_to_smiles(g::Graph)::String
    if isempty(g.nodes)
        return ""
    end

    # --- 1. Prepare Adjacency & Aromaticity ---
    adj = Dict{Int, Vector{Tuple{Int,Int}}}()
    aromatic_atoms = Set{Int}()

    for id in keys(g.nodes)
        adj[id] = Tuple{Int,Int}[]
    end

    for e in g.edges
        push!(adj[e.from], (e.to, e.order))
        push!(adj[e.to], (e.from, e.order))
        
        if e.order == 4
            push!(aromatic_atoms, e.from)
            push!(aromatic_atoms, e.to)
        end
    end
    
    # Sort neighbors strictly by ID for deterministic Spanning Tree
    for (k, v) in adj
        sort!(v, by = x -> x[1])
    end

    # --- 2. Determine Start Node ---
    start_node = minimum(keys(g.nodes))
    for id in sort(collect(keys(g.nodes)))
        if g.nodes[id].label != "H"
            start_node = id
            break
        end
    end

    # --- 3. Pass 1: Ring Detection & Spanning Tree Build ---
    tree_edges = Set{Tuple{Int,Int}}()
    ring_closures = Dict{Tuple{Int,Int}, Int}()
    ring_openings = Dict{Int, Vector{Int}}()
    
    visited_depth = Dict{Int, Int}()
    current_ring_id = 1
    
    function build_spanning_tree(u::Int, parent::Int, depth::Int)
        visited_depth[u] = depth
        
        for (v, w) in adj[u]
            if v == parent; continue; end
            
            if haskey(visited_depth, v)
                if visited_depth[v] < depth
                    rid = current_ring_id
                    current_ring_id += 1
                    
                    ring_closures[(u, v)] = rid
                    
                    if !haskey(ring_openings, v)
                        ring_openings[v] = Int[]
                    end
                    push!(ring_openings[v], rid)
                end
            else
                push!(tree_edges, (u, v))
                build_spanning_tree(v, u, depth + 1)
            end
        end
    end
    
    build_spanning_tree(start_node, -1, 0)

    # --- 4. Pass 2: Generation ---
    io = IOBuffer()
    
    function format_ring_id(rid::Int)
        return rid < 10 ? "$rid" : "%$rid"
    end

    function get_bond_symbol(order::Int)
        if order == 2; return "="
        elseif order == 3; return "#"
        elseif order == 4; return "" # Implicit aromatic (included but for now not used.. :( )
        else; return ""
        end
    end

    function generate_dfs(u::Int)
        lbl = g.nodes[u].label
        if u in aromatic_atoms
            lbl = lowercase(lbl)
        end
        print(io, "[$lbl]") # [] necessary for explicit H handling
        
        # B. Print Ring OPENINGS (Suffix)
        if haskey(ring_openings, u)
            for rid in sort(ring_openings[u])
                print(io, format_ring_id(rid))
            end
        end
        
        neighbors = adj[u]
        
        # C. Print Ring CLOSURES (Suffix)
        for (v, w) in neighbors
            if haskey(ring_closures, (u, v))
                rid = ring_closures[(u, v)]
                print(io, get_bond_symbol(w))
                print(io, format_ring_id(rid))
            end
        end
        
        # D. Process Children (Tree Edges) as BRANCHES
        children = []
        for (v, w) in neighbors
            if ((u, v) in tree_edges)
                push!(children, (v, w))
            end
        end
        
        num_children = length(children)
        for (i, (v, w)) in enumerate(children)
            is_last = (i == num_children)
            
            if !is_last; print(io, "("); end
            
            print(io, get_bond_symbol(w))
            generate_dfs(v)
            
            if !is_last; print(io, ")"); end
        end
    end
    
    generate_dfs(start_node)
    
    return String(take!(io))
end