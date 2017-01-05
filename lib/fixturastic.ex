if Mix.env == :test do
  defmodule DevRepo do
    use Ecto.Repo, otp_app: Mix.Project.config[:app]
  end

  defmodule Fixturist do
    import Ecto.Query

    def serialize(resource) do
      relationships = resource.__struct__.__schema__(:associations)
      Map.drop(resource, [:__meta__, :__struct__] ++ relationships)
    end

    def start_dev_repo do
      DevRepo.start_link
    end

    def insert_all(model, array) do
      belongs_to_relationships = find_belongs_to_relationships(model)

      operation_list = form_operation_list(model, array, []) |> order_operation_list

      Repo.transaction(fn ->
        operation_list |> Enum.each(fn(operation) ->
          struct_array = operation |> elem(1) |> Enum.map(fn(x) ->
            serialize(x)
          end)

          Repo.insert_all(operation |> elem(0), struct_array, returning: true)
        end)

        array_data = array |> Enum.map(fn(record) ->
          # NOTE: this shouldnt be very good what about twoWordRelationship attr?
          # this should probably be cast/3 instead of serialize
          record |> Map.put_new(:__struct__, model) |> serialize()
        end)

        Repo.insert_all(model, array_data, returning: true)
      end)
    end

    def insert!(model, map) do
      belongs_to_relationships = find_belongs_to_relationships(model)

      operation_list = form_operation_list(model, [map], []) |> order_operation_list

      Repo.transaction(fn ->
        operation_list |> Enum.each(fn(operation) ->
          struct_array = operation |> elem(1) |> Enum.map(fn(x) ->
            serialize(x)
          end)

          Repo.insert_all(operation |> elem(0), struct_array, returning: true)
        end)

        ecto_map = map |> Map.put_new(:__struct__, model) |> serialize()
        struct(model, map) |> Repo.insert!
      end)
    end

    def order_operation_list(operation_list) do
      score_list = operation_list |> Enum.map(fn(operation) ->
        operation_model = operation |> elem(0)
        {
          operation_model,
          operation |> elem(1),
          find_belongs_to_relationships(operation_model) |> length
        }
      end) |> Enum.sort_by(fn(x) -> x |> elem(2) end)
    end

    def merge_new_operations_to_operation_list(new_list, operation_list) do
      new_list |> Enum.reduce(operation_list, fn(list_tuple, accum) ->
        reference_in_operation_list = operation_list |> Enum.find(fn(operation_list_tuple) ->
          (operation_list_tuple |> elem(0)) == (list_tuple |> elem(0))
        end)

        case reference_in_operation_list do
          nil -> [list_tuple | accum]
          reference_in_operation_list ->
            values = (
              (reference_in_operation_list |> elem(1)) ++ (list_tuple |> elem(1))
            ) |> Enum.uniq

            reference_model_key = reference_in_operation_list |> elem(0)

            reference_index = Enum.find_index(operation_list, fn(operation) ->
               operation |> elem(0) == reference_model_key
            end)

            List.replace_at(operation_list, reference_index, {reference_model_key, values})
        end
      end)
    end

    def form_operation_list(model, [], operation_list), do: operation_list

    def form_operation_list(model, records_to_dissect, prior_operation_list) do
      belongs_to_relationships = find_belongs_to_relationships(model)

      belongs_to_relationships |> Enum.reduce(prior_operation_list, fn(relationship, accum) ->
        relationship_model = get_relationship_model(model, relationship)

        record_ids = records_to_dissect |> Enum.map(fn(x) ->
          relationship_field = belongs_to_relationship_to_field(relationship)
          x |> Map.get(relationship_field)
        end) |> Enum.uniq

        records_found = from(
          record in relationship_model,
          select: record,
          where: record.id in ^record_ids
        ) |> DevRepo.all

        case records_found do
          [] -> accum
          records_found ->
            relationship_tuple = [{relationship_model, records_found}]
            new_list = merge_new_operations_to_operation_list(relationship_tuple, accum)
            form_operation_list(relationship_model, records_found, new_list)
        end
      end)
    end

    def find_belongs_to_relationship_fields(model) do
      find_belongs_to_relationships(model) |> Enum.map(fn(relationship) ->
        belongs_to_relationship_to_field(relationship)
      end)
    end

    def belongs_to_relationship_to_field(relationship) do
      field = (relationship |> Atom.to_string) <> "_id" |> String.to_atom
    end

    def find_belongs_to_relationships(model) do
      model.__schema__(:fields) |> Enum.reduce([], fn(field, acc) ->
        possible_relation = field |> Atom.to_string |> String.slice(0..-4) |> String.to_atom
        case model.__schema__(:associations) |> Enum.member?(possible_relation) do
          true -> acc ++ [possible_relation]
          false -> acc
        end
      end)
    end

    def get_relationship_model(model, relationship) do
      model.__schema__(:association, relationship).queryable
    end
  end
end
