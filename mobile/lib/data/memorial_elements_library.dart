import 'package:flutter/material.dart';
import '../models/memorial_element.dart';

class MemorialElementsLibrary {
  static const List<String> verseCategories = [
    'Classic Tributes',
    'Scripture & Prayers',
    'Short & Sweet',
    'Celebration of Life',
  ];

  static const List<MemorialVerse> verses = [
    // Classic Tributes
    MemorialVerse(
      id: 'v1',
      category: 'Classic Tributes',
      title: 'Eternal Peace',
      text: 'May your soul find eternal peace, and may your light continue to shine in our hearts forever.',
    ),
    MemorialVerse(
      id: 'v2',
      category: 'Classic Tributes',
      title: 'Walk Beside Us',
      text: 'Those we love don\'t go away, they walk beside us every day. Unseen, unheard, but always near.',
    ),
    MemorialVerse(
      id: 'v3',
      category: 'Classic Tributes',
      title: 'Forever Missed',
      text: 'Forever loved, forever missed, and forever remembered by family and friends.',
    ),
    MemorialVerse(
      id: 'v4',
      category: 'Classic Tributes',
      title: 'In Our Hearts',
      text: 'In our hearts you hold a place no one else will ever fill. We cherish every memory.',
    ),
    MemorialVerse(
      id: 'v5',
      category: 'Classic Tributes',
      title: 'Beautiful Life',
      text: 'A beautiful life came to an end, she died as she lived, everyone\'s friend.',
    ),

    // Scripture & Prayers
    MemorialVerse(
      id: 'v6',
      category: 'Scripture & Prayers',
      title: 'Psalm 23:4',
      text: 'Even though I walk through the darkest valley, I will fear no evil, for you are with me.',
    ),
    MemorialVerse(
      id: 'v7',
      category: 'Scripture & Prayers',
      title: 'Matthew 5:4',
      text: 'Blessed are those who mourn, for they shall be comforted.',
    ),
    MemorialVerse(
      id: 'v8',
      category: 'Scripture & Prayers',
      title: 'John 14:1',
      text: 'Do not let your hearts be troubled. You believe in God; believe also in me.',
    ),
    MemorialVerse(
      id: 'v9',
      category: 'Scripture & Prayers',
      title: '2 Timothy 4:7',
      text: 'I have fought the good fight, I have finished the race, I have kept the faith.',
    ),
    MemorialVerse(
      id: 'v10',
      category: 'Scripture & Prayers',
      title: 'Peaceful Prayer',
      text: 'Lord, grant eternal rest unto them, and let perpetual light shine upon their soul.',
    ),

    // Short & Sweet
    MemorialVerse(
      id: 'v11',
      category: 'Short & Sweet',
      title: 'Always in Our Hearts',
      text: 'You will always be in our hearts and minds.',
    ),
    MemorialVerse(
      id: 'v12',
      category: 'Short & Sweet',
      title: 'Until We Meet Again',
      text: 'Until we meet again, rest in heavenly peace.',
    ),
    MemorialVerse(
      id: 'v13',
      category: 'Short & Sweet',
      title: 'Forever Loved',
      text: 'Gone too soon, but never forgotten.',
    ),
    MemorialVerse(
      id: 'v14',
      category: 'Short & Sweet',
      title: 'Cherished Memories',
      text: 'Your memory is a keepsake from which we will never part.',
    ),
    MemorialVerse(
      id: 'v15',
      category: 'Short & Sweet',
      title: 'Rest in Peace',
      text: 'Rest peacefully in the arms of angels.',
    ),

    // Celebration of Life
    MemorialVerse(
      id: 'v16',
      category: 'Celebration of Life',
      title: 'Life Well Lived',
      text: 'Celebrating a life well lived, full of joy, kindness, and boundless love.',
    ),
    MemorialVerse(
      id: 'v17',
      category: 'Celebration of Life',
      title: 'Smile & Remember',
      text: 'Don\'t cry because it\'s over, smile because it happened. Thank you for the memories.',
    ),
    MemorialVerse(
      id: 'v18',
      category: 'Celebration of Life',
      title: 'Legacy of Love',
      text: 'Your legacy of kindness and generosity lives on in all of us.',
    ),
    MemorialVerse(
      id: 'v19',
      category: 'Celebration of Life',
      title: 'Shining Bright',
      text: 'A star that burned so brightly will continue to guide our paths forever.',
    ),
    MemorialVerse(
      id: 'v20',
      category: 'Celebration of Life',
      title: 'Love Never Ends',
      text: 'Love never ends. Your spirit remains interwoven with ours forever.',
    ),
  ];

  // ── FLORAL OVERLAYS ──────────────────────────────────────────────────────────
  // These match exactly the web dashboard's flowers section.
  // Images are served from the backend at /flowers/{imageFile}
  static const List<MemorialGraphic> graphics = [
    MemorialGraphic(
      id: 'floral_white_roses',
      category: 'Floral Designs',
      name: 'White Roses',
      imageFile: 'floral_white_roses.png',
    ),
    MemorialGraphic(
      id: 'floral_gold_leaves',
      category: 'Floral Designs',
      name: 'Gold Leaves',
      imageFile: 'floral_gold_leaves.png',
    ),
    MemorialGraphic(
      id: 'floral_cherry_blossom',
      category: 'Floral Designs',
      name: 'Cherry Blossom',
      imageFile: 'floral_cherry_blossom.png',
    ),
    MemorialGraphic(
      id: 'floral_forget_me_not',
      category: 'Floral Designs',
      name: 'Forget-me-not',
      imageFile: 'floral_forget_me_not.png',
    ),
    MemorialGraphic(
      id: 'floral_olive_branch',
      category: 'Floral Designs',
      name: 'Olive Branch',
      imageFile: 'floral_olive_branch.png',
    ),
    MemorialGraphic(
      id: 'floral_lavender',
      category: 'Floral Designs',
      name: 'Lavender',
      imageFile: 'floral_lavender.png',
    ),
    MemorialGraphic(
      id: 'floral_lilies_frame',
      category: 'Floral Designs',
      name: 'Lilies Frame',
      imageFile: 'floral_lilies_frame.png',
    ),
    MemorialGraphic(
      id: 'floral_peonies',
      category: 'Floral Designs',
      name: 'Peonies',
      imageFile: 'floral_peonies.png',
    ),
    MemorialGraphic(
      id: 'floral_ferns_corner',
      category: 'Floral Designs',
      name: 'Ferns Corner',
      imageFile: 'floral_ferns_corner.png',
    ),
    MemorialGraphic(
      id: 'floral_daisy_divider',
      category: 'Floral Designs',
      name: 'Daisy Divider',
      imageFile: 'floral_daisy_divider.png',
    ),
    MemorialGraphic(
      id: 'original_golden_floral',
      category: 'Full Overlays',
      name: 'Golden Floral',
      imageFile: 'original_golden_floral.png',
    ),
    MemorialGraphic(
      id: 'original_classic_ivory',
      category: 'Full Overlays',
      name: 'Classic Ivory',
      imageFile: 'original_classic_ivory.png',
    ),
    MemorialGraphic(
      id: 'original_dark_moody',
      category: 'Full Overlays',
      name: 'Dark Moody',
      imageFile: 'original_dark_moody.png',
    ),
    MemorialGraphic(
      id: 'original_subtle_corner',
      category: 'Full Overlays',
      name: 'Subtle Corner',
      imageFile: 'original_subtle_corner.png',
    ),
    MemorialGraphic(
      id: 'original_elegant_geometric',
      category: 'Full Overlays',
      name: 'Elegant Geometric',
      imageFile: 'original_elegant_geometric.png',
    ),
    MemorialGraphic(
      id: 'original_blue_hydrangea',
      category: 'Full Overlays',
      name: 'Blue Hydrangea',
      imageFile: 'original_blue_hydrangea.png',
    ),
    MemorialGraphic(
      id: 'original_soft_blush',
      category: 'Full Overlays',
      name: 'Soft Blush',
      imageFile: 'original_soft_blush.png',
    ),
    MemorialGraphic(
      id: 'original_vintage_sepia',
      category: 'Full Overlays',
      name: 'Vintage Sepia',
      imageFile: 'original_vintage_sepia.png',
    ),
    MemorialGraphic(
      id: 'original_white_orchid',
      category: 'Full Overlays',
      name: 'White Orchid',
      imageFile: 'original_white_orchid.png',
    ),
    MemorialGraphic(
      id: 'original_peace_lily',
      category: 'Full Overlays',
      name: 'Peace Lily',
      imageFile: 'original_peace_lily.png',
    ),
  ];

  static List<MemorialVerse> getVersesByCategory(String category) {
    return verses.where((v) => v.category == category).toList();
  }

  static List<MemorialGraphic> getGraphicsByCategory(String category) {
    return graphics.where((g) => g.category == category).toList();
  }
}
