import 'package:flutter/material.dart';
import '../../../core/models/artwork_model.dart';

class ArtworkDetailScreen extends StatefulWidget {
  final ArtworkModel artwork;

  const ArtworkDetailScreen({Key? key, required this.artwork})
    : super(key: key);

  @override
  State<ArtworkDetailScreen> createState() => _ArtworkDetailScreenState();
}

class _ArtworkDetailScreenState extends State<ArtworkDetailScreen> {
  late bool _isLiked;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.artwork.isLikedByMe;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artwork Details'),
        actions: [IconButton(icon: Icon(Icons.share), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                widget.artwork.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  );
                },
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  if (widget.artwork.title != null)
                    Text(
                      widget.artwork.title!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Artist
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: widget.artwork.user.avatarUrl != null
                              ? NetworkImage(widget.artwork.user.avatarUrl!)
                              : null,
                          child: widget.artwork.user.avatarUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.artwork.user.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (widget.artwork.user.isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              '@${widget.artwork.user.email.split('@')[0]}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Description
                  if (widget.artwork.description != null)
                    Text(
                      widget.artwork.description!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  const SizedBox(height: 16),
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('Likes', widget.artwork.likesCount),
                      _buildStatColumn(
                        'Comments',
                        widget.artwork.commentsCount,
                      ),
                      _buildStatColumn('Remixes', widget.artwork.remixCount),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _isLiked = !_isLiked);
                          },
                          icon: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                          ),
                          label: Text(_isLiked ? 'Liked' : 'Like'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLiked
                                ? Colors.red
                                : Colors.grey[300],
                            foregroundColor: _isLiked
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.comment),
                          label: const Text('Comment'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.repeat),
                          label: const Text('Remix'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Remix info
                  if (widget.artwork.remixedFrom != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Remixed from',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.artwork.remixedFrom!.user.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Metadata
                  if (widget.artwork.description != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Details',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildMetadataRow(
                            'Created',
                            _formatDate(widget.artwork.createdAt),
                          ),
                          _buildMetadataRow(
                            'Visibility',
                            widget.artwork.isPublic ? 'Public' : 'Private',
                          ),
                          if (widget.artwork.isNSFW)
                            _buildMetadataRow(
                              'Content',
                              'Contains NSFW content',
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
