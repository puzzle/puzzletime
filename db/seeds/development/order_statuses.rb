OrderStatus.seed(:name,
  { name: 'Bearbeitung',
    style: 'success',
    position: 10 },

  { name: 'Abschluss',
    style: 'info',
    position: 20 },

  { name: 'Abgeschlossen',
    style: 'danger',
    position: 30,
    closed: true },
)
