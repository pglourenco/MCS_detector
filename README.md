# MCS_detector

A Julia tool for identifying the **Maximum Common Substructure (MCS)** between two small aliphatic molecules.

The program accepts two molecules in **SMILES** format, converts them into graph representations, identifies their MCS, converts the resulting graph back to SMILES, and generates structural visualizations.

This project was developed as part of a university software project in **chemoinformatics**. The MCS workflow was implemented without relying on established chemoinformatics toolkits such as RDKit, with the aim of exploring the underlying graph-based algorithms.

## Features

* Parses aliphatic molecules from SMILES
* Converts molecular structures into graph representations
* Adds explicit hydrogen atoms
* Computes the Maximum Common Substructure between two molecules
* Converts the resulting MCS graph back to SMILES
* Generates SVG visualizations of the input molecules and MCS
* Exports molecular graphs as adjacency lists
* Handles invalid, empty, and unsupported aromatic inputs

> **Note:** The current implementation is intended for small aliphatic molecules. Aromatic molecules are not currently supported.

## Requirements

* **Julia 1.6+**
* **MolecularGraph.jl**

Install MolecularGraph from the Julia package manager:

```julia
using Pkg
Pkg.add("MolecularGraph")
```

Alternatively, enter Julia's package mode by pressing `]` and run:

```text
add MolecularGraph
```

## Installation

Clone the repository:

```bash
git clone <repository-url>
cd MCS_detector
```

The main source files are:

```text
main_pipeline.jl
SMILES_to_graph.jl
MCS_Algorithm.jl
graph_to_SMILES.jl
visualize_smiles.jl
```

## Usage

Run the main pipeline from the project directory:

```bash
julia main_pipeline.jl
```

The program will prompt you to enter two aliphatic molecules as SMILES strings.

For example:

```text
Enter 1st aliphatic SMILES: CCO
Enter 2nd aliphatic SMILES: CCCO
```

Here, the molecules are **ethanol (`CCO`)** and **1-propanol (`CCCO`)**.

The program then:

1. Generates structural representations of both input molecules.
2. Converts the molecules into graphs.
3. Searches for their Maximum Common Substructure.
4. Converts the MCS back into SMILES.
5. Generates a visualization of the resulting MCS.

Example result:

```text
[Step 4] Finding Maximum Common Substructure...
   -> MCS Size: 8 atoms (with H)

[Step 5] Converting MCS to SMILES...
   -> Result: [C]([C]([O][H])([H])[H])([H])[H]

[Step 6] Visualizing MCS...
   -> Visualized (As Is): output_mcs.svg
```

## Output Files

A successful calculation generates:

```text
input_1.svg       # Structure of molecule 1
input_2.svg       # Structure of molecule 2
output_mcs.svg    # Maximum Common Substructure

graph_1.graph     # Graph representation of molecule 1
graph_2.graph     # Graph representation of molecule 2
graph_mcs.graph   # Graph representation of the MCS
```

The `.graph` files contain adjacency-list representations of the molecular graphs, including atom identities and bond information.

## No Common Substructure

If no common structure satisfying the matching criteria is found, the program reports:

```text
[Step 4] Finding Maximum Common Substructure...
   -> No common structure found.
```

For example, hydrazine (`NN`) and bromoethane (`CCBr`) do not share a common heavy-atom substructure under the implemented matching criteria.

In this case, the input molecule graphs and visualizations are still generated, but no MCS graph, SMILES, or visualization is produced.

## Limitations

The software was developed primarily for educational purposes and is not intended as a replacement for established cheminformatics libraries.

Current limitations include:

* Aromatic molecules are not supported.
* The implementation is intended primarily for small molecules.
* SMILES parsing supports only the features required by the scope of the project.
* Performance is not optimized for large molecular graphs.

## Project Structure

```text
MCS_detector/
├── main_pipeline.jl
├── SMILES_to_graph.jl
├── MCS_Algorithm.jl
├── graph_to_SMILES.jl
├── visualize_smiles.jl
├── README.md
└── LICENSE
```

## Authors

Developed by **Pedro Lourenço** and **Fabio Golini** as a university project in chemoinformatics and software development.

## License

This project is licensed under the **MIT License**. See [`LICENSE`](LICENSE) for details.
