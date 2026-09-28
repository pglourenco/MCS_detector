# ==============================================================================
# MODULE: SMILES VISUALIZER (Configurable)
# ==============================================================================

using MolecularGraph


function visualize_molecule(smiles::String, filename::String; show_all_h::Bool=false) # If show_all_h true force the addition of all implicit hydrogens to the graph
    if isempty(smiles)                                                                # If false draw exactly what is written in the SMILES.
        println("   ! Warning: Empty SMILES passed to visualizer.")
        return
    end

    try
        # 1. Parsing base
        mol = smilestomol(smiles)

        # 2. adding hydrogen if needded
        if show_all_h
            add_hydrogens!(mol)
        end

        # 3. Draw SMILES (using MolecularGraph's function)
        open(filename, "w") do f
            write(f, drawsvg(mol, width=300, height=300))
        end
        
        mode_str = show_all_h ? "Explicit H Added" : "As Is"
        println("   -> Visualized ($mode_str): $filename")

    catch e
        println("   ! Error visualizing \"$smiles\": $e")
    end
end