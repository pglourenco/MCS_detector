# ==============================================================================
# MODULE: SMILES TO GRAPH CONVERTER (AROMATIC OK)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. SHARED DATA STRUCTURES
# ------------------------------------------------------------------------------
struct Node
    id::Int
    label::String
end

struct Edge
    from::Int
    to::Int
    order::Int # 1=Single, 2=Double, 3=Triple, 4=Aromatic
end

struct Graph
    nodes::Dict{Int, Node}
    edges::Vector{Edge}
end

# ------------------------------------------------------------------------------
# 2. CONVERSION LOGIC
# ------------------------------------------------------------------------------

function smiles_to_graph(smiles::String)::Graph
    # Standard Valence for main organic elements
    VALENCE = Dict("C"=>4, "N"=>3, "O"=>2, "S"=>2, "F"=>1, "Cl"=>1, "Br"=>1, "I"=>1, "P"=>5)
    
    nodes = Dict{Int, Node}()
    edges = Vector{Edge}()
    
    atoms = String[]
    # Set to track which atom IDs are aromatic
    aromatic_indices = Set{Int}()
    
    # Adjacency: NodeID -> List of (NeighborID, BondOrder)
    adj_temp = Dict{Int, Vector{Tuple{Int,Int}}}()
    
    # Ring Tracker
    ring_tracker = Dict{Char, Int}()
    
    stack = Int[]
    previous_id = 0
    current_bond_order = 1
    # Flag to check if the user explicitly typed a bond (-, =, #)
    is_explicit_bond = false 
    
    clean_s = replace(smiles, "["=>"", "]"=>"")
    
    i = 1
    len = length(clean_s)
    
    while i <= len
        char = clean_s[i]
        
        if char == '('
            push!(stack, previous_id)
            i += 1
        elseif char == ')'
            if !isempty(stack)
                previous_id = pop!(stack)
            end
            i += 1
        elseif char == '-'
            current_bond_order = 1
            is_explicit_bond = true
            i += 1
        elseif char == '='
            current_bond_order = 2
            is_explicit_bond = true
            i += 1
        elseif char == '#'
            current_bond_order = 3
            is_explicit_bond = true
            i += 1
            
        # --- Ring Closure (Cyclic) ---
        elseif isdigit(char)
            if haskey(ring_tracker, char)
                # CLOSE RING
                origin_id = ring_tracker[char]
                
                # Determine Bond Order for Ring Closure
                final_order = current_bond_order
                
                # If no explicit bond was given, and both atoms are aromatic -> Order 4
                if !is_explicit_bond && 
                   (origin_id in aromatic_indices) && 
                   (previous_id in aromatic_indices)
                    final_order = 4
                end
                
                if previous_id > 0
                    push!(adj_temp[previous_id], (origin_id, final_order))
                    push!(adj_temp[origin_id], (previous_id, final_order))
                end
                
                delete!(ring_tracker, char)
            else
                # OPEN RING
                ring_tracker[char] = previous_id
            end
            
            # Reset bond flags after consuming digit (bond was essentially "used" by the number)
            is_explicit_bond = false 
            current_bond_order = 1
            i += 1
            
        # --- Atom Parsing ---
        elseif isletter(char)
            sym = ""
            is_atom_aromatic = false
            
            # 1. Check for two-letter elements (e.g. Cl, Br)
            if isuppercase(char) && i + 1 <= len && islowercase(clean_s[i+1])
                sym = string(char) * clean_s[i+1]
                i += 2
            else
                # 2. Single letter: Check Aromaticity (lowercase)
                if islowercase(char)
                    is_atom_aromatic = true
                    sym = string(uppercase(char)) # Store as Uppercase (C, N, O)
                else
                    sym = string(char)
                end
                i += 1
            end
            
            # Register Atom
            push!(atoms, sym)
            curr_id = length(atoms)
            adj_temp[curr_id] = []
            
            if is_atom_aromatic
                push!(aromatic_indices, curr_id)
            end
            
            # Connect to Previous
            if previous_id > 0
                final_order = current_bond_order
                
                # Logic: If no explicit bond (-,=,#) and both are aromatic -> Order 4
                if !is_explicit_bond && 
                   (curr_id in aromatic_indices) && 
                   (previous_id in aromatic_indices)
                    final_order = 4
                end
                
                push!(adj_temp[curr_id], (previous_id, final_order))
                push!(adj_temp[previous_id], (curr_id, final_order))
            end
            
            previous_id = curr_id
            # Reset state for next atom
            current_bond_order = 1
            is_explicit_bond = false
        else
            i += 1
        end
    end
    
    # --- Step B: Add Explicit Hydrogens ---
    
    num_heavy = length(atoms)
    h_count = num_heavy
    
    for k in 1:num_heavy
        sym = atoms[k]
        
        used_valence = 0.0
        if haskey(adj_temp, k)
            for (n, w) in adj_temp[k]
                if w == 4
                    used_valence += 1.5
                else
                    used_valence += Float64(w)
                end
            end
        end
        
        max_v = get(VALENCE, sym, 0)
        
        # Calculate needed H
        needed = Int(floor(max_v - used_valence))
        
        if needed > 0
            for _ in 1:needed
                h_count += 1
                push!(atoms, "H")
                adj_temp[h_count] = []
                push!(adj_temp[k], (h_count, 1))
                push!(adj_temp[h_count], (k, 1))
            end
        end
    end
    
    # --- Step C: Build Graph Objects ---
    for k in 1:length(atoms)
        nodes[k] = Node(k, atoms[k])
    end
    
    seen_edges = Set{Tuple{Int,Int}}()
    for u in keys(adj_temp)
        for (v, w) in adj_temp[u]
            pair = (min(u,v), max(u,v))
            if !(pair in seen_edges)
                push!(edges, Edge(min(u,v), max(u,v), w))
                push!(seen_edges, pair)
            end
        end
    end
    
    return Graph(nodes, edges)
end