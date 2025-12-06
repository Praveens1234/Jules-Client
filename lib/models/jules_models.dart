class Session {
  final String name;
  final String id;
  final String title;
  final String prompt;
  final SourceContext? sourceContext;

  Session({
    required this.name,
    required this.id,
    required this.title,
    required this.prompt,
    this.sourceContext,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      name: json['name'] ?? '',
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled Session',
      prompt: json['prompt'] ?? '',
      sourceContext: json['sourceContext'] != null 
          ? SourceContext.fromJson(json['sourceContext']) 
          : null,
    );
  }
}

class SourceContext {
  final String source;
  final GithubRepoContext? githubRepoContext;

  SourceContext({required this.source, this.githubRepoContext});

  factory SourceContext.fromJson(Map<String, dynamic> json) {
    return SourceContext(
      source: json['source'] ?? '',
      githubRepoContext: json['githubRepoContext'] != null
          ? GithubRepoContext.fromJson(json['githubRepoContext'])
          : null,
    );
  }
}

class GithubRepoContext {
  final String startingBranch;

  GithubRepoContext({required this.startingBranch});

  factory GithubRepoContext.fromJson(Map<String, dynamic> json) {
    return GithubRepoContext(
      startingBranch: json['startingBranch'] ?? '',
    );
  }
}

class Source {
  final String name;
  final String id;
  final GithubRepo? githubRepo;

  Source({required this.name, required this.id, this.githubRepo});

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      name: json['name'] ?? '',
      id: json['id'] ?? '',
      githubRepo: json['githubRepo'] != null 
          ? GithubRepo.fromJson(json['githubRepo']) 
          : null,
    );
  }
}

class GithubRepo {
  final String owner;
  final String repo;

  GithubRepo({required this.owner, required this.repo});

  factory GithubRepo.fromJson(Map<String, dynamic> json) {
    return GithubRepo(
      owner: json['owner'] ?? '',
      repo: json['repo'] ?? '',
    );
  }
}

class Activity {
  final String name;
  final String id;
  final String createTime;
  final String originator; // 'agent' or 'user'
  final ProgressUpdated? progressUpdated;
  final PlanGenerated? planGenerated;
  final PlanApproved? planApproved;
  final Artifacts? artifacts;

  Activity({
    required this.name,
    required this.id,
    required this.createTime,
    required this.originator,
    this.progressUpdated,
    this.planGenerated,
    this.planApproved,
    this.artifacts,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      name: json['name'] ?? '',
      id: json['id'] ?? '',
      createTime: json['createTime'] ?? '',
      originator: json['originator'] ?? 'unknown',
      progressUpdated: json['progressUpdated'] != null
          ? ProgressUpdated.fromJson(json['progressUpdated'])
          : null,
      planGenerated: json['planGenerated'] != null
          ? PlanGenerated.fromJson(json['planGenerated'])
          : null,
      planApproved: json['planApproved'] != null
          ? PlanApproved.fromJson(json['planApproved'])
          : null,
    );
  }
}

class ProgressUpdated {
  final String title;
  final String description;

  ProgressUpdated({required this.title, this.description = ''});

  factory ProgressUpdated.fromJson(Map<String, dynamic> json) {
    return ProgressUpdated(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class PlanGenerated {
  final Plan plan;
  
  PlanGenerated({required this.plan});

  factory PlanGenerated.fromJson(Map<String, dynamic> json) {
    return PlanGenerated(
      plan: Plan.fromJson(json['plan'] ?? {}),
    );
  }
}

class Plan {
  final String id;
  final List<PlanStep> steps;

  Plan({required this.id, required this.steps});

  factory Plan.fromJson(Map<String, dynamic> json) {
    final List<dynamic> stepsJson = json['steps'] ?? [];
    return Plan(
      id: json['id'] ?? '',
      steps: stepsJson.map((e) => PlanStep.fromJson(e)).toList(),
    );
  }
}

class PlanStep {
  final String id;
  final String title;
  final int index;

  PlanStep({required this.id, required this.title, required this.index});

  factory PlanStep.fromJson(Map<String, dynamic> json) {
    return PlanStep(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      index: json['index'] ?? 0,
    );
  }
}

class PlanApproved {
  final String planId;

  PlanApproved({required this.planId});

  factory PlanApproved.fromJson(Map<String, dynamic> json) {
    return PlanApproved(
      planId: json['planId'] ?? '',
    );
  }
}

class Artifacts {
  // Placeholder for complex artifacts
}
