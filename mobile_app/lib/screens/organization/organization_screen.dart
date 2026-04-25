// lib/screens/organization/organization_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'financial_dashboard_screen.dart';

class OrganizationScreen extends ConsumerStatefulWidget {
  const OrganizationScreen({super.key});

  @override
  ConsumerState<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends ConsumerState<OrganizationScreen> {
  Map<String, dynamic>? organization;
  List<Map<String, dynamic>> members = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrganization();
  }

  Future<void> _loadOrganization() async {
    try {
      final response = await apiService.getOrganization();
      setState(() {
        organization = response['organization'];
        members = response['members'] ?? [];
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load organization: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (organization == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.buildingUser,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No Organization Found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Create an organization to manage your team',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _showCreateOrganizationDialog(),
                child: const Text('Create Organization'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 120, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Organization Header
            _OrganizationHeader(organization: organization!),
            const SizedBox(height: 32),
            
            // Stats Cards
            _StatsCards(organization: organization!, members: members),
            const SizedBox(height: 16),
            
            // Financial Dashboard Button
            _FinancialDashboardButton(),
            const SizedBox(height: 32),
            
            // Team Members Section
            _TeamMembersSection(
              members: members,
              onInvite: () => _showInviteMemberDialog(),
              onRefresh: _loadOrganization,
            ),
            const SizedBox(height: 32),
            
            // Settings Section
            _SettingsSection(organization: organization!),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInviteMemberDialog(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  void _showCreateOrganizationDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateOrganizationDialog(
        onCreated: (org) {
          setState(() {
            organization = org;
            members = [];
          });
          _loadOrganization();
        },
      ),
    );
  }

  void _showInviteMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => _InviteMemberDialog(
        organizationId: organization!['id'],
        onInvited: _loadOrganization,
      ),
    );
  }
}

// ─── Organization Header ─────────────────────────────────────────────────────

class _OrganizationHeader extends StatelessWidget {
  final Map<String, dynamic> organization;

  const _OrganizationHeader({required this.organization});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(
                  FontAwesomeIcons.building,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      organization['name'] ?? 'Organization',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${organization['plan']?.toString().toUpperCase() ?? 'FREE'} Plan',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // Edit organization
                },
                icon: Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stats Cards ───────────────────────────────────────────────────────────

class _StatsCards extends StatelessWidget {
  final Map<String, dynamic> organization;
  final List<Map<String, dynamic>> members;

  const _StatsCards({
    required this.organization,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Team Members',
            value: '${members.length}',
            subtitle: '/ ${organization['maxMembers'] ?? 5}',
            icon: FontAwesomeIcons.users,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Active Workflows',
            value: '0',
            subtitle: 'Automations',
            icon: FontAwesomeIcons.robot,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Monthly Volume',
            value: '\$0',
            subtitle: 'Transactions',
            icon: FontAwesomeIcons.chartLine,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final FaIconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Team Members Section ─────────────────────────────────────────────────────

class _TeamMembersSection extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final VoidCallback onInvite;
  final VoidCallback onRefresh;

  const _TeamMembersSection({
    required this.members,
    required this.onInvite,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Team Members',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onInvite,
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Invite'),
                ),
              ],
            ),
          ),
          if (members.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  FaIcon(
                    FontAwesomeIcons.userGroup,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No team members yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Invite team members to collaborate',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: onInvite,
                    child: const Text('Invite First Member'),
                  ),
                ],
              ),
            )
          else
            ...members.map((member) => _MemberTile(member: member)).toList(),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Map<String, dynamic> member;

  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final role = member['role'] ?? 'staff';
    final user = member['user'] ?? {};
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Text(
                (user['fullName'] ?? user['email'] ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['fullName'] ?? user['businessName'] ?? 'Unknown',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user['email'] ?? 'No email',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            _RoleChip(role: role),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    String displayRole;
    
    switch (role.toLowerCase()) {
      case 'owner':
        color = Colors.purple;
        displayRole = 'Owner';
        break;
      case 'admin':
        color = Colors.blue;
        displayRole = 'Admin';
        break;
      case 'manager':
        color = Colors.green;
        displayRole = 'Manager';
        break;
      default:
        color = Colors.grey;
        displayRole = 'Staff';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayRole,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Financial Dashboard Button ─────────────────────────────────────────────

class _FinancialDashboardButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(
                  FontAwesomeIcons.chartLine,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Dashboard',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View team revenue, transactions, and performance metrics',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OrganizationFinancialDashboardScreen(),
              ),
            ),
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('View Dashboard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Section ───────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final Map<String, dynamic> organization;

  const _SettingsSection({required this.organization});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Organization Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _SettingTile(
            icon: FontAwesomeIcons.crown,
            title: 'Upgrade Plan',
            subtitle: 'Unlock more features and team members',
            onTap: () {
              // Navigate to upgrade
            },
          ),
          _SettingTile(
            icon: FontAwesomeIcons.shieldHalved,
            title: 'Security Settings',
            subtitle: 'Manage permissions and access control',
            onTap: () {
              // Navigate to security
            },
          ),
          _SettingTile(
            icon: FontAwesomeIcons.fileInvoice,
            title: 'Billing & Invoices',
            subtitle: 'View billing history and manage subscriptions',
            onTap: () {
              // Navigate to billing
            },
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final FaIconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: FaIcon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Create Organization Dialog ───────────────────────────────────────────────

class _CreateOrganizationDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onCreated;

  const _CreateOrganizationDialog({required this.onCreated});

  @override
  State<_CreateOrganizationDialog> createState() => _CreateOrganizationDialogState();
}

class _CreateOrganizationDialogState extends State<_CreateOrganizationDialog> {
  final _nameController = TextEditingController();
  final _domainController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => loading = true);
    try {
      final response = await apiService.createOrganization({
        'name': _nameController.text.trim(),
        'domain': _domainController.text.trim().isEmpty ? null : _domainController.text.trim(),
      });

      widget.onCreated(response['organization']);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Organization created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create organization: $e')),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Organization',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set up your organization to manage team members and workflows',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Organization Name',
                hintText: 'e.g., Acme Corp',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _domainController,
              decoration: const InputDecoration(
                labelText: 'Domain (Optional)',
                hintText: 'e.g., acme.corp',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: loading ? null : _create,
                  child: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Invite Member Dialog ─────────────────────────────────────────────────────

class _InviteMemberDialog extends StatefulWidget {
  final String organizationId;
  final VoidCallback onInvited;

  const _InviteMemberDialog({
    required this.organizationId,
    required this.onInvited,
  });

  @override
  State<_InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<_InviteMemberDialog> {
  final _emailController = TextEditingController();
  String _selectedRole = 'staff';
  bool loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    if (_emailController.text.trim().isEmpty) return;

    setState(() => loading = true);
    try {
      await apiService.inviteOrganizationMember({
        'organizationId': widget.organizationId,
        'email': _emailController.text.trim(),
        'role': _selectedRole,
      });

      widget.onInvited();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation sent successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send invitation: $e')),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invite Team Member',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send an invitation to join your organization',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'team@company.com',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
              ),
              items: const [
                DropdownMenuItem(value: 'staff', child: Text('Staff')),
                DropdownMenuItem(value: 'manager', child: Text('Manager')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) => setState(() => _selectedRole = value!),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: loading ? null : _invite,
                  child: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send Invitation'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
