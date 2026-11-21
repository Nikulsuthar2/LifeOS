import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/skill.dart';
import '../repositories/skill_repository.dart';

class SkillStatusFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setStatus(String val) => state = val;
}

final skillStatusFilterProvider = NotifierProvider<SkillStatusFilterNotifier, String>(SkillStatusFilterNotifier.new);

class SkillDomainFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setDomain(String val) => state = val;
}

final skillDomainFilterProvider = NotifierProvider<SkillDomainFilterNotifier, String>(SkillDomainFilterNotifier.new);

final skillsListProvider = FutureProvider<List<PolymathSkill>>((ref) async {
  final repo = ref.watch(skillRepositoryProvider);
  final status = ref.watch(skillStatusFilterProvider);
  final domain = ref.watch(skillDomainFilterProvider);

  return await repo.getSkills(status: status, domain: domain);
});

final skillDomainsProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(skillRepositoryProvider);
  return await repo.getUniqueDomains();
});
