# ==============================================================================
# MAIN PIPELINE
# ==============================================================================

# 1. Import files
include("SMILES_to_graph.jl")
include("MCS_Algorithm.jl")
include("graph_to_SMILES.jl")
include("visualize_SMILES.jl")

function main()
    println("==========================================")
    println("      MOLECULAR MCS PIPELINE (JULIA)      ")
    println("       FOR ALIPHATIC COMPOUNDS ONLY       ")
    println("==========================================")

    # ---------------------------------------------------------
    # 1. Get User Input
    # ---------------------------------------------------------
    println("\n[Step 1] Input")
    print("Enter 1st aliphatic SMILES: ")
    s1 = readline()
    if isempty(s1); println("ERROR, enter a valid SMILES"); return; end
    if occursin(r"[cn]", s1)
       println("Sorry, the program is not able to handle aromatics yet")
       return
    end

    print("Enter 2nd aliphatic SMILES: ")
    s2 = readline()
    if isempty(s2); println("ERROR, enter a valid SMILES"); return; end
    if occursin(r"[cn]", s2)
       println("Sorry, the program is not able to handle aromatics yet")
       return
    end
   
    println("   Molecule 1: $s1")
    println("   Molecule 2: $s2")

    # ---------------------------------------------------------
    # 2. Visualize Inputs
    # ---------------------------------------------------------
    println("\n[Step 2] Visualizing Inputs...")
    visualize_molecule(s1, "input_1.svg", show_all_h=true)
    visualize_molecule(s2, "input_2.svg", show_all_h=true)

    # ---------------------------------------------------------
    # 3. Convert to Graph Structures
    # ---------------------------------------------------------
    println("\n[Step 3] Parsing to Graphs...")
    
    g1 = smiles_to_graph(s1)
    write_graph(g1, "graph_1.graph"; title="Graph for Molecule 1")

    g2 = smiles_to_graph(s2)
    write_graph(g2, "graph_2.graph"; title="Graph for Molecule 2")

    println("   -> Mol 1 Nodes: $(length(g1.nodes))")
    println("   -> Mol 2 Nodes: $(length(g2.nodes))")

    # ---------------------------------------------------------
    # 4. Find Maximum Common Substructure (MCS)
    # ---------------------------------------------------------
    println("\n[Step 4] Finding Maximum Common Substructure...")
    
    mcs_heavy, mapping = mcs_connected_bondmax(g1, g2)
    
    if isempty(mcs_heavy.nodes)
        println("   -> No common structure found.")
        return
    end

    # Restore Hydrogens
    mcs_full = restore_hydrogens(mcs_heavy, g1, g2, mapping)
    write_graph(mcs_full, "graph_mcs.graph"; title="MCS Graph with Hydrogens")
    
    println("   -> MCS Size: $(length(mcs_full.nodes)) atoms (with H)")

    # ---------------------------------------------------------
    # 5. Convert MCS Graph -> SMILES
    # ---------------------------------------------------------
    println("\n[Step 5] Converting MCS to SMILES...")
    mcs_smiles = graph_to_smiles(mcs_full)
    println("   -> Result: $mcs_smiles")

    # ---------------------------------------------------------
    # 6. Visualize the Result
    # ---------------------------------------------------------
    println("\n[Step 6] Visualizing MCS...")
    visualize_molecule(mcs_smiles, "output_mcs.svg", show_all_h=false)
    
    println("\n==========================================")
    println("Done! Check 'output_mcs.svg'.")
end

# Run the main functiion
main()