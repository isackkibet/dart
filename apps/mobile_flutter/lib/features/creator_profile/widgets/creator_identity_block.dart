import 'package:flutter/material.dart';

class CreatorIdentityBlock extends StatelessWidget {
  const CreatorIdentityBlock({
    required this.displayName,
    required this.username,
    required this.verified,
    required this.onOpenProfile,
    super.key,
  });

  final String displayName;
  final String username;
  final bool verified;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open profile for $displayName, @$username',
      child: InkWell(
        key: const ValueKey('creator-identity-block'),
        onTap: onOpenProfile,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      key: const ValueKey('creator-display-name'),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (verified) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified,
                      key: ValueKey('creator-verification-badge'),
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ],
              ),
              if (username.isNotEmpty)
                Text(
                  '@$username',
                  key: const ValueKey('creator-username'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
