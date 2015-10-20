module ContractsHelper
  def format_contract_notes(contract)
    auto_link(simple_format(contract.notes))
  end

  def format_contract_sla(contract)
    auto_link(simple_format(contract.sla))
  end
end
