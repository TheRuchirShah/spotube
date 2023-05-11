import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:collection/collection.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:spotube/collections/spotube_icons.dart';
import 'package:spotube/components/shared/fallbacks/anonymous_fallback.dart';
import 'package:spotube/components/artist/artist_card.dart';
import 'package:spotube/extensions/context.dart';
import 'package:spotube/provider/authentication_provider.dart';
import 'package:spotube/services/queries/queries.dart';
import 'package:tuple/tuple.dart';

class UserArtists extends HookConsumerWidget {
  const UserArtists({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(AuthenticationNotifier.provider);

    final artistQuery = useQueries.artist.followedByMeAll(ref);

    final searchText = useState('');

    final filteredArtists = useMemoized(() {
      final artists = artistQuery.data ?? [];

      if (searchText.value.isEmpty) {
        return artists.toList();
      }
      return artists
          .map((e) => Tuple2(
                weightedRatio(e.name!, searchText.value),
                e,
              ))
          .sorted((a, b) => b.item1.compareTo(a.item1))
          .where((e) => e.item1 > 50)
          .map((e) => e.item2)
          .toList();
    }, [artistQuery.data, searchText.value]);

    final controller = useScrollController();

    if (auth == null) {
      return const AnonymousFallback();
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ColoredBox(
            color: theme.scaffoldBackgroundColor,
            child: TextField(
              onChanged: (value) => searchText.value = value,
              decoration: InputDecoration(
                prefixIcon: const Icon(SpotubeIcons.filter),
                hintText: context.l10n.filter_artist,
              ),
            ),
          ),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: artistQuery.data?.isEmpty == true
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 10),
                  Text(context.l10n.loading),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await artistQuery.refresh();
              },
              child: SingleChildScrollView(
                controller: controller,
                child: SizedBox(
                  width: double.infinity,
                  child: SafeArea(
                    child: Center(
                      child: Wrap(
                        spacing: 15,
                        runSpacing: 5,
                        children: filteredArtists
                            .mapIndexed((index, artist) => ArtistCard(artist))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
