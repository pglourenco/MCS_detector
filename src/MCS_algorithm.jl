# ==============================================================================
# MODULE: MCS ALGORITHM (Adapted from Pedro's Logic)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. GRAPH UTILITIES
# ------------------------------------------------------------------------------
function node_ids(g::Graph; ignore_h::Bool=false)::Vector{Int}
    ids = sort(collect(keys(g.nodes)))
    return ignore_h ? [i for i in ids if g.nodes[i].label != "H"] : ids
end

function edge_map(g::Graph)::Dict{Tuple{Int,Int},Int}
    em = Dict{Tuple{Int,Int},Int}()
    for e in g.edges
        # Ensure we use (min, max) key for undirected lookup
        k = e.from < e.to ? (e.from, e.to) : (e.to, e.from)
        em[k] = e.order
    end
    return em
end

# Generate adjacency list 
# Node -> [(Neighbor, Order)]
function get_adjacency(g::Graph)::Dict{Int, Vector{Tuple{Int,Int}}}
    adj = Dict{Int, Vector{Tuple{Int,Int}}}()
    for id in keys(g.nodes)
        adj[id] = Tuple{Int,Int}[]
    end
    for e in g.edges
        push!(adj[e.from], (e.to, e.order))
        push!(adj[e.to], (e.from, e.order))
    end
    return adj
end

function attached_hydrogens(g::Graph, n::Int)::Vector{Int}
    adj = get_adjacency(g)
    hs = Int[]
    # Check neighbors; if neighbor is H and bond is single (1), add it
    neighbors = get(adj, n, [])
    for (nb, order) in neighbors
        if order == 1 && haskey(g.nodes, nb) && g.nodes[nb].label == "H"
            push!(hs, nb)
        end
    end
    return hs
end

# ------------------------------------------------------------------------------
# CORE MCS LOGIC (Connected + Bond-Max)
# ------------------------------------------------------------------------------
function mcs_connected_bondmax(g1::Graph, g2::Graph; ignore_h::Bool=true)
    ids1 = node_ids(g1; ignore_h=ignore_h)
    ids2 = node_ids(g2; ignore_h=ignore_h)
    em1 = edge_map(g1)
    em2 = edge_map(g2)
    adj1 = get_adjacency(g1)
    adj2 = get_adjacency(g2)

    # Pre-compute labels
    label_to_ids2 = Dict{String,Vector{Int}}()
    for id in ids2
        lbl = g2.nodes[id].label
        push!(get!(label_to_ids2, lbl, Int[]), id)
    end

    best_map = Dict{Int,Int}()
    best_size = -1


    # Try starting from every compatible pair to ensure we find the region
    for u1 in ids1
        lbl = g1.nodes[u1].label
        potential_starts = get(label_to_ids2, lbl, Int[])
        
        for u2 in potential_starts
            curr_map = Dict(u1 => u2)
            candidates = [] # Queue of (n1, n2) to check
            
            # Local function to add neighbors to queue
            function add_candidates!(q, n1, n2, c_map)
                neighs1 = get(adj1, n1, [])
                neighs2 = get(adj2, n2, [])
                
                for (nb1, w1) in neighs1
                    if nb1 in keys(c_map); continue; end
                    if ignore_h && g1.nodes[nb1].label == "H"; continue; end
                    
                    for (nb2, w2) in neighs2
                        if nb2 in values(c_map); continue; end
                        if ignore_h && g2.nodes[nb2].label == "H"; continue; end
                        
                        # Match condition: Label + Bond Order
                        if g1.nodes[nb1].label == g2.nodes[nb2].label && w1 == w2
                            push!(q, (nb1, nb2))
                        end
                    end
                end
            end
            
            add_candidates!(candidates, u1, u2, curr_map)
            
            # Grow Region
            while !isempty(candidates)
                (c1, c2) = popfirst!(candidates)
                
                if !haskey(curr_map, c1) && !(c2 in values(curr_map))
                    curr_map[c1] = c2
                    add_candidates!(candidates, c1, c2, curr_map)
                end
            end
            
            # Keep the best result
            if length(curr_map) > best_size
                best_size = length(curr_map)
                best_map = copy(curr_map)
            end
        end
    end

    # Build Heavy MCS Graph
    m_nodes = Dict{Int, Node}()
    m_edges = Vector{Edge}()
    
    # Add Nodes
    for (u1, u2) in best_map
        m_nodes[u1] = Node(u1, g1.nodes[u1].label)
    end
    
    # Add Edges (if both ends are in MCS and bond matches)
    for e in g1.edges
        if haskey(best_map, e.from) && haskey(best_map, e.to)
            u2, v2 = best_map[e.from], best_map[e.to]
            
            # Check if this edge exists in G2 with same order
            k2 = u2 < v2 ? (u2, v2) : (v2, u2)
            if haskey(em2, k2) && em2[k2] == e.order
                push!(m_edges, Edge(e.from, e.to, e.order))
            end
        end
    end
    
    return Graph(m_nodes, m_edges), best_map
end

# ------------------------------------------------------------------------------
# HYDROGEN RESTORATION
# ------------------------------------------------------------------------------
function restore_hydrogens(g_mcs_heavy::Graph, g1::Graph, g2::Graph, mapping::Dict{Int,Int})::Graph
    new_nodes = copy(g_mcs_heavy.nodes)
    new_edges = copy(g_mcs_heavy.edges)
    
    # Find a safe ID to start numbering new Hydrogens
    max_id = 0
    if !isempty(new_nodes); max_id = maximum(keys(new_nodes)); end
    next_id = max_id 

    for (u1, u2) in mapping
        # Calculate how many H are attached to the atom in Mol1 vs Mol2
        h1 = attached_hydrogens(g1, u1)
        h2 = attached_hydrogens(g2, u2)
        
        # keep the minimum common number of Hydrogens
        num_common = min(length(h1), length(h2))
        
        for _ in 1:num_common
            next_id += 1
            new_nodes[next_id] = Node(next_id, "H")
            
            # Add single bond
            a, b = min(u1, next_id), max(u1, next_id)
            push!(new_edges, Edge(a, b, 1))
        end
    end
    
    return Graph(new_nodes, new_edges)
end

function write_graph(g::Graph, filename::String; title::String)
    adj = adjacency(g)
    open(filename, "w") do io
        println(io, "# ", title)
        for id in sort(collect(keys(g.nodes)))
            lab = g.nodes[id].label
            neigh = get(adj, id, Tuple{Int,Int}[])
            if isempty(neigh)
                println(io, "$(id) ($(lab)):")
            else
                # format: (neighbor,order) (neighbor,order) ...
                s = join(["($(nb),$(ord))" for (nb, ord) in neigh], " ")
                println(io, "$(id) ($(lab)): ", s)
            end
        end
    end
end

function adjacency(g::Graph)::Dict{Int, Vector{Tuple{Int,Int}}}
    adj = Dict{Int, Vector{Tuple{Int,Int}}}()
    for id in keys(g.nodes)
        adj[id] = Tuple{Int,Int}[]
    end
    for e in g.edges
        if !haskey(adj, e.from) || !haskey(adj, e.to)
            error("Edge references missing node: $(e.from) --$(e.order)-- $(e.to)")
        end
        push!(adj[e.from], (e.to, e.order))
        push!(adj[e.to], (e.from, e.order))
    end

    # sort neighbors for deterministic output
    for (k, v) in adj
        sort!(v, by = x -> x[1])
    end
    return adj
end