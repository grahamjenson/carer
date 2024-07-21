abstract class DataMapper<T1, T2> {
  const DataMapper();
  T2 from(T1 model);
  List<T2> map(List<T1> models) {
    return models.map(from).toList();
  }
}
