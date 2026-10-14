class PersonDetails {
  final String? overview;
  final String? birthDate;
  final String? deathDate;
  final String? birthPlace;

  const PersonDetails({this.overview, this.birthDate, this.deathDate, this.birthPlace});

  bool get isEmpty => overview == null && birthDate == null && deathDate == null && birthPlace == null;
}
