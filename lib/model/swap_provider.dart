import 'package:flutter/material.dart';
import 'package:komodo_dex/blocs/swap_history_bloc.dart';
import 'package:komodo_dex/model/recent_swaps.dart';
import 'package:komodo_dex/model/swap.dart';
import 'package:komodo_dex/services/mm.dart';
import 'package:komodo_dex/services/mm_service.dart';
import 'package:komodo_dex/utils/log.dart';

import 'error_string.dart';
import 'get_recent_swap.dart';

class SwapProvider extends ChangeNotifier {
  SwapProvider() {
    syncSwaps.linkProvider(this);
  }
  @override
  void dispose() {
    syncSwaps.unlinkProvider(this);
    super.dispose();
  }

  void notify() => notifyListeners();

  Iterable<Swap> get swaps => syncSwaps.swaps;
  Swap swap(String uuid) => syncSwaps.swap(uuid);
}

SyncSwaps syncSwaps = SyncSwaps();

/// In ECS terms it is a System coordinating the swap information,
/// keeping in sync with MM and decentralized gossip.
class SyncSwaps {
  /// [ChangeNotifier] proxies linked to this singleton.
  final Set<SwapProvider> _providers = {};

  /// Loaded from MM.
  Map<String, Swap> _swaps = {};

  /// Maps swap UUIDs to gossip entities created from our swaps.
  final Map<String, SwapGossip> _ours = {};

  /// Link a [ChangeNotifier] proxy to this singleton.
  void linkProvider(SwapProvider provider) {
    _providers.add(provider);
  }

  /// Unlink a [ChangeNotifier] proxy from this singleton.
  void unlinkProvider(SwapProvider provider) {
    _providers.remove(provider);
  }

  Iterable<Swap> get swaps {
    return _swaps.values;
  }

  /// Fresh status of swap [uuid].
  /// cf. https://developers.komodoplatform.com/basic-docs/atomicdex/atomicdex-api.html#my-swap-status
  Swap swap(String uuid) {
    return _swaps[uuid];
  }

  void _notifyListeners() {
    for (SwapProvider provider in _providers) provider.notify();
  }

  /// (Re)load recent swaps from MM.
  Future<void> update(String reason) async {
    Log.println('swap_provider:68', 'update] reason $reason');

    final dynamic rswaps = await MM.getRecentSwaps(
        MMService().client, GetRecentSwap(limit: 50, fromUuid: null));

    if (rswaps is ErrorString) {
      Log.println('swap_provider:74', '!getRecentSwaps: ${rswaps.error}');
      return;
    }
    if (rswaps is! RecentSwaps) throw Exception('!RecentSwaps');

    final Map<String, Swap> swaps = {};
    for (ResultSwap rswap in rswaps.result.swaps) {
      final Status status = swapHistoryBloc.getStatusSwap(rswap);
      final String uuid = rswap.uuid;
      swaps[uuid] = Swap(result: rswap, status: status);
      _gossip(rswap);
    }

    _swaps = swaps;
    _notifyListeners();
  }

  /// Share swap information on dexp2p.
  void _gossip(ResultSwap rswap) {
    // See if we have already gossiped about this version of the swap.
    if (rswap.events.isEmpty) return;
    final String uuid = rswap.uuid;
    final int timestamp = rswap.events.last.timestamp;
    if (_ours[uuid]?.timestamp == timestamp) return;

    Log.println('swap_provider:99', 'gossiping of $uuid; $timestamp');
    final SwapGossip gossip = SwapGossip();
    gossip.timestamp = timestamp;
    _ours[uuid] = gossip;
  }
}

class SwapGossip {
  /// Time of last swap event, in milliseconds since UNIX epoch.
  int timestamp;
}
