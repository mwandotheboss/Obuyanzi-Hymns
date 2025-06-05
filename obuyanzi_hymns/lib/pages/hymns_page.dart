import 'package:flutter/material.dart';
import '../models/hymn.dart';
import '../services/hymn_service.dart';
import 'hymn_detail_page.dart';

enum LanguagePreference { english, luhya, both }

class HymnsPage extends StatefulWidget {
  final String userId;
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const HymnsPage({
    super.key,
    required this.userId,
    required this.onToggleTheme,
    required this.themeMode,
  });

  @override
  State<HymnsPage> createState() => _HymnsPageState();
}

class _HymnsPageState extends State<HymnsPage> {
  final HymnService _hymnService = HymnService();
  LanguagePreference _languagePreference = LanguagePreference.both;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hymns Collection',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<LanguagePreference>(
                value: _languagePreference,
                items: const [
                  DropdownMenuItem(
                    value: LanguagePreference.english,
                    child: Text('English'),
                  ),
                  DropdownMenuItem(
                    value: LanguagePreference.luhya,
                    child: Text('Luhya'),
                  ),
                  DropdownMenuItem(
                    value: LanguagePreference.both,
                    child: Text('Both'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _languagePreference = value;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<List<Hymn>>(
              stream: _hymnService.getHymns(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final hymns = snapshot.data ?? [];

                int crossAxisCount = 3;
                double width = MediaQuery.of(context).size.width;
                if (width < 600) {
                  crossAxisCount = 1;
                } else if (width < 900) {
                  crossAxisCount = 2;
                }
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: hymns.length,
                  itemBuilder: (context, index) {
                    final hymn = hymns[index];
                    return Card(
                      elevation: 2,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HymnDetailPage(
                                hymnId: hymn.id,
                                userId: widget.userId,
                                onToggleTheme: widget.onToggleTheme,
                                themeMode: widget.themeMode,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Hymn ${hymn.number}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _languagePreference == LanguagePreference.english
                                    ? hymn.titleEnglish ?? ''
                                    : _languagePreference == LanguagePreference.luhya
                                        ? hymn.titleLuhya
                                        : '${hymn.titleEnglish ?? ''}\n${hymn.titleLuhya}',
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_languagePreference == LanguagePreference.both) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'English & Luhya',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 