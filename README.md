# MCS_detector
## Description
This project implements a software tool written in Julia for comparing small aliphatic molecules by 
finding their Maximum Common Substructure (MCS). 
The program takes two aliphatic molecules as input in SMILES format, converts them into a graph where 
atoms are nodes and bonds are edges, computes their MCS, and produces a structural and visual 
representation of the result. 
This project was produced with the intention for educational use in chemoinformatics and software 
development, and it does not rely on external chemoinformatics libraries such as RDKit, although it 
would make the code simpler and more efficient.
## Quick start instructions
 
2.4 Expected outputs 
1. Console output: Upon successful execution, the terminal will display a log detailing the processing 
steps, node counts, and the final SMILES result. The output must match the following format: 
[Step 1] Input 
Enter 1st aliphatic SMILES: CCO 
Enter 2nd aliphatic SMILES: CCCO 
   Molecule 1: CCO 
   Molecule 2: CCCO 
 
[Step 2] Visualizing Inputs... 
   -> Visualized (Explicit H Added): input_1.svg 
   -> Visualized (Explicit H Added): input_2.svg 
 
[Step 3] Parsing to Graphs... 
   -> Mol 1 Nodes: 9 
   -> Mol 2 Nodes: 12 
 
[Step 4] Finding Maximum Common Substructure... 
 5 
   -> MCS Size: 8 atoms (with H) 
 
[Step 5] Converting MCS to SMILES... 
   -> Result: [C]([C]([O][H])([H])[H])([H])[H] 
 
[Step 6] Visualizing MCS... 
   -> Visualized (As Is): output_mcs.svg 
 
========================================== 
Done! Check 'output_mcs.svg'. 
2. Generated files: After the program terminates, verify that the following 6 files have been created in 
the working directory: 
Structure images (.svg): 
1. input_1.svg (Visualized input 1 with explicit hydrogens) 
2. input_2.svg (Visualized input 2 with explicit hydrogens) 
3. output_mcs.svg (Visualized MCS result) 
Graph data files (.graph): 
4. graph_1.graph (Adjacency list for molecule 1) 
5. graph_2.graph (Adjacency list for molecule 2) 
6. graph_mcs.graph (Adjacency list for the MCS) 
Having used the ethanol (CCO) and n-propanol (CCCO) SMILES, the specific output files are reported 
in the following table. 
Table 1 SMILES representations, molecular structure visualizations (SVG), and corresponding adjacency-list 
graph files for the two input molecules (ethanol and n-propanol) and for the resulting Maximum Common 
Substructure (MCS).  
 SMILE & Structure images (.svg) Graph data files (.graph) 
Input 1 
ethanol 
CCO # Graph for Molecule 1 
1 (C): (2,1) (4,1) (5,1) (6,1) 
2 (C): (1,1) (3,1) (7,1) (8,1) 
3 (O): (2,1) (9,1) 
4 (H): (1,1) 
5 (H): (1,1) 
6 (H): (1,1) 
 6 
 
7 (H): (2,1) 
8 (H): (2,1) 
9 (H): (3,1) 
Input 2 
n-propanol 
CCCO 
 
# Graph for Molecule 2 
1 (C): (2,1) (5,1) (6,1) (7,1) 
2 (C): (1,1) (3,1) (8,1) (9,1) 
3 (C): (2,1) (4,1) (10,1) (11,1) 
4 (O): (3,1) (12,1) 
5 (H): (1,1) 
6 (H): (1,1) 
7 (H): (1,1) 
8 (H): (2,1) 
9 (H): (2,1) 
10 (H): (3,1) 
11 (H): (3,1) 
12 (H): (4,1) 
MCS [C]([C]([O][H])([H])[H])([H])[H] 
 
# MCS Graph with Hydrogens 
1 (C): (2,1) (7,1) (8,1) 
2 (C): (1,1) (3,1) (4,1) (5,1) 
3 (O): (2,1) (6,1) 
4 (H): (2,1) 
5 (H): (2,1) 
6 (H): (3,1) 
7 (H): (1,1) 
8 (H): (1,1) 
The specific content format and structure of the .graph files are explained in detail in the  
User manual section. 
3. No MCS: If the two input molecules do not share a minimum common chemical structure, the 
program correctly identifies the absence of a Maximum Common Substructure (MCS) and terminates 
the MCS computation step without producing an MCS output. 
For example, when using hydeazine (NN) and bromoethane (CCBr) as input molecules, no common 
substructure satisfying the matching criteria can be found. 
During execution, the following message is printed in the terminal: 
[Step 4] Finding Maximum Common Substructure... -> No common structure found.. 
In this case: 
 
 
 
no graph_mcs.graph file is generated, 
no MCS SMILES string is produced, 
no MCS visualization file is created. 
However, the program still completes the earlier steps of the pipeline, so the visualization and graph 
files for the two input molecules will still be created. 
For this specific example, the generated input files are reported in the following table. 
Note: Based on the logic of MCS algorithms, to generate a result where no common structure is 
found, you must compare two molecules that share no common heavy atoms (e.g., Carbon vs. 
Nitrogen). Otherwise any two standard organic molecules (which by definition contain Carbon) will 
share at least one Carbon atom as a common substructure. 
Table 2 Summary of inputs and outputs for the MCS analysis of hydrazine and bromoethane. No Maximum 
Common Substructure (MCS) was found; therefore, no MCS output files were generated. 
SMILE & Structure images (.svg) Graph data files (.graph) 
Input 1 
Hydrazine 
NN 
# Graph for Molecule 1 
1 (N): (2,1) (3,1) (4,1) 
2 (N): (1,1) (5,1) (6,1) 
3 (H): (1,1) 
4 (H): (1,1) 
5 (H): (2,1) 
6 (H): (2,1) 
Input 2 
CCBr 
# Graph for Molecule 2 
7 
 8 
Bromoethane 
 
1 (C): (2,1) (4,1) (5,1) (6,1) 
2 (C): (1,1) (3,1) (7,1) (8,1) 
3 (Br): (2,1) 
4 (H): (1,1) 
5 (H): (1,1) 
6 (H): (1,1) 
7 (H): (2,1) 
8 (H): (2,1) 
MCS -> No common structure found. -> No common structure found. 
