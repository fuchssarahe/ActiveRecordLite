require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)


      define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      search_params = {
        source_table: source_options.table_name,
        source_primary: source_options.primary_key,
        source_foreign: source_options.foreign_key,

        through_table: through_options.table_name,
        through_primary: through_options.primary_key,
        through_foreign: through_options.foreign_key,

        current_table: self.class.table_name,
      }

      search_params[:current_instance_id] = self.send(search_params[:through_foreign])

      results = DBConnection.execute(<<-SQL)
        SELECT
          #{search_params[:source_table]}.*
        FROM
          #{search_params[:source_table]}
          JOIN #{search_params[:through_table]}
          ON #{search_params[:source_table]}.#{search_params[:source_primary]} = #{search_params[:through_table]}.#{search_params[:source_foreign]}
          WHERE
            #{search_params[:through_table]}.#{search_params[:through_primary]} = #{search_params[:current_instance_id]}
      SQL

      source_options.model_class.parse_all(results).first
    end


    # Below uses multiple quesries - bad! Should use only one.

    # define_method(name) do
    #   self.send(through_name).send(source_name)
    # end
  end
end
