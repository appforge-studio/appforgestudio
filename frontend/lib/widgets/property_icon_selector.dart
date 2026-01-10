import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/arri_client.rpc.dart';

import '../utilities/pallet.dart';

class PropertyIconSelector extends StatefulWidget {
  final Function(String) onIconSelected;

  const PropertyIconSelector({super.key, required this.onIconSelected});

  @override
  State<PropertyIconSelector> createState() => _PropertyIconSelectorState();
}

class _PropertyIconSelectorState extends State<PropertyIconSelector> {
  final TextEditingController _searchController = TextEditingController();
  List<SvgInfo> _svgs = [];
  bool _isLoading = false;
  int _total = 0;
  int _offset = 0;
  final int _limit = 50;

  String? _searchQuery;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchSvgs();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSvgs({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _svgs = [];
        _offset = 0;
      }
    });

    try {
      final client = Get.find<ArriClient>();
      debugPrint(
        'Fetching SVGs with query: "$_searchQuery", offset: $_offset, limit: $_limit',
      );
      final response = await client.svg.get_svgs(
        GetSvgsParams(limit: _limit, offset: _offset, search: _searchQuery),
      );
      debugPrint(
        'Fetch response: success=${response.success}, count=${response.svgs.length}, total=${response.total}',
      );

      if (response.success) {
        setState(() {
          _svgs.addAll(response.svgs);
          _total = response.total;
          _offset += response.svgs.length;
        });
      } else {
        debugPrint('Failed to fetch SVGs: ${response.message}');
      }
    } catch (e) {
      debugPrint('Error fetching SVGs: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Pallet.inside1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Pallet.inside1,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Select Icon',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Pallet.font1,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Pallet.font2),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              style: TextStyle(color: Pallet.font1),
              decoration: InputDecoration(
                labelText: 'Search Icons',
                labelStyle: TextStyle(color: Pallet.font3),
                filled: true,
                fillColor: Pallet.inside2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: Pallet.font3),
              ),
              onChanged: (value) {
                debugPrint('Search input: $value');
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  debugPrint('Debounce fired. Query: "$value"');
                  _searchQuery = value.isEmpty ? null : value;
                  _fetchSvgs(refresh: true);
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (!_isLoading &&
                      scrollInfo.metrics.pixels ==
                          scrollInfo.metrics.maxScrollExtent &&
                      _svgs.length < _total) {
                    _fetchSvgs();
                  }
                  return true;
                },
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _svgs.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _svgs.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final svg = _svgs[index];
                    return InkWell(
                      onTap: () {
                        widget.onIconSelected(svg.svg);
                        Get.back();
                      },
                      child: Tooltip(
                        message: svg.name,
                        child: Card(
                          color: Pallet.inside2,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SvgPicture.string(
                              svg.svg,
                              colorFilter: ColorFilter.mode(
                                Pallet.font1,
                                BlendMode.srcIn,
                              ),
                              placeholderBuilder: (_) =>
                                  const Icon(Icons.error),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
