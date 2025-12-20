import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:speedview/common/navigation/app_routes.dart';
import 'package:speedview/common/widgets/speedview_app_bar.dart';
import 'package:speedview/common/widgets/speedview_drawer.dart';
import '../models/circuit_model.dart';
import '../widgets/circuit_card.dart';
import 'circuit_detail_screen.dart';
import 'circuit_form_screen.dart';

class CircuitListScreen extends StatefulWidget {
  const CircuitListScreen({super.key});

  @override
  State<CircuitListScreen> createState() => _CircuitListScreenState();
}

class _CircuitListScreenState extends State<CircuitListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Circuit> _allCircuits = [];
  List<Circuit> _filteredCircuits = [];
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCircuits();
    });
  }

  Future<void> _fetchCircuits() async {
    final request = context.read<CookieRequest>();
    const String url = 'https://helven-marcia-speedview.pbp.cs.ui.ac.id/circuit/api/';
    
    try {
      final response = await request.get(url);
      if (response['ok'] == true) {
        final List<dynamic> data = response['data'];
        final circuits = data.map((json) {
          return Circuit.fromJson(json);
        }).toList();
        bool isAdminUser = circuits.isNotEmpty ? circuits.first.isAdmin : false;

        setState((){
          _allCircuits = circuits;
          _filteredCircuits = circuits;
          _isAdmin = isAdminUser;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching circuits: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterCircuits(String query) {
    setState(() {
      _filteredCircuits = _allCircuits.where((c) {
        final q = query.toLowerCase();
        return c.name.toLowerCase().contains(q) ||
               c.country.toLowerCase().contains(q) ||
               c.location.toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<void> _deleteCircuit(int id) async {
    final request = context.read<CookieRequest>();
    final url = 'https://helven-marcia-speedview.pbp.cs.ui.ac.id/circuit/api/$id/delete/';
    
    try {
      final response = await request.post(url, {});
      if (response['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Circuit deleted successfully"), backgroundColor: Colors.green),
        );
        _fetchCircuits(); // Refresh data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? "Failed to delete"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _showDeleteConfirmation(Circuit circuit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Delete Circuit', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete ${circuit.name}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCircuit(circuit.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF05070B);
    const cardColor = Color(0xFF0F151F);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const SpeedViewAppBar(title: 'Circuits'),
      drawer: const SpeedViewDrawer(currentRoute: AppRoutes.circuits),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFFFB4D46),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CircuitFormScreen()),
                );
                if (result == true) _fetchCircuits();
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Add Circuit", 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Back
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Search Bar
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            onChanged: _filterCircuits,
                            decoration: InputDecoration(
                              hintText: 'Search circuit...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                              prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFB4D46)))
                  : _filteredCircuits.isEmpty
                      ? Center(child: Text('No circuits found.', style: TextStyle(color: Colors.white.withOpacity(0.5))))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = constraints.maxWidth < 600 ? 2 : 4;                            
                            double childAspectRatio = constraints.maxWidth < 600 ? 0.85 : 0.9;

                            return GridView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount, 
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: childAspectRatio,
                              ),
                              itemCount: _filteredCircuits.length,
                              itemBuilder: (context, index) {
                                final circuit = _filteredCircuits[index];
                                return CircuitCard(
                                  circuit: circuit,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CircuitDetailScreen(circuit: circuit),
                                      ),
                                    );
                                  },
                                  onEdit: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CircuitFormScreen(circuit: circuit),
                                      ),
                                    );
                                    if (result == true) _fetchCircuits();
                                  },
                                  onDelete: () => _showDeleteConfirmation(circuit),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}