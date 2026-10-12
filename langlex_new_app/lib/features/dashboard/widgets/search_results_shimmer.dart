import 'package:flutter/material.dart';
import 'package:langlex_new_app/features/learning/widgets/content_shimmers.dart';

class SearchResultsShimmer extends StatelessWidget {
  const SearchResultsShimmer({
    super.key,
    required this.label,
    this.alphabetGrid = false,
    this.kind = CatalogSkeleton.courses,
  });

  final String label;
  final bool alphabetGrid;
  final CatalogSkeleton kind;

  @override
  Widget build(BuildContext context) => CatalogShimmer(
    label: label,
    kind: alphabetGrid ? CatalogSkeleton.alphabets : kind,
    itemCount: alphabetGrid ? 6 : 4,
  );
}
