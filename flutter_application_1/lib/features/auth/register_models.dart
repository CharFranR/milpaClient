enum RegisterRole {
  agricultor(1),
  compradorMinorista(2),
  compradorMayoristaDetallista(3),
  compradorMayoristaCorporativo(4);

  const RegisterRole(this.roleId);

  final int roleId;
}
