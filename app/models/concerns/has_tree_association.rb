# encoding: utf-8

module HasTreeAssociation

  include Conditioner

  def sum(column_name)
    descendant_scope.sum(column_name)
  end

  def find(*args)
    # TODO wire that up for rails 4
    case args.first
      when :first, :all then
        @klass.descendant_scope.find(args.first, options)
      else
        @klass.find(args)
    end
  end

  def count(column_name)
    descendant_scope.count(column_name)
  end

  private

  def descendant_scope
    joins(:project).
           where("worktimes.project_id = projects.id AND " \
                 "#{@association.owner.id} = ANY (projects.path_ids)")
  end

end
