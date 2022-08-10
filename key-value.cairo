%builtins output range_check

from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.squash_dict import squash_dict
from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.alloc import alloc

struct KeyValue:
    member key : felt
    member value : felt
end

func main{output_ptr : felt*, range_check_ptr}():
    alloc_locals

    local fn_list : KeyValue*
    local size

    %{
        hint_list = program_input['list']

        ids.fn_list = fn_list = segments.add()
        for i, val in enumerate(hint_list):
            memory[fn_list + i] = val
        ids.size = len(hint_list)
    
    %}

    sum_by_key(list=fn_list,size=size)
    return()
end

# Builds a DictAccess list for the computation of the cumulative
# sum for each key.


func build_dict(list : KeyValue*, size, dict : DictAccess*) -> (
    dict
):
    if size == 0:
        return (dict=dict)
    end

    %{
        if ids.list.key in cumulative_sums:
            ids.dict.prev_value = cumulative_sums["ids.list.key"]
            cumulative_sums["ids.list.key"] += ids.list.value
            ids.dict.new_value = cumulative_sums["ids.list.key"]
        else:
            ids.dict.prev_value = 0
            cumulative_sums["ids.list.key"] += ids.list.values
            ids.dict.new_value = cumulative_sums["ids.list.key"]
        # Populate ids.dict.prev_value using cumulative_sums...
        # Add list.value to cumulative_sums[list.key]...
        

    %}
    # Copy list.key to dict.key...
    # Verify that dict.new_value = dict.prev_value + list.value...
    # Call recursively to build_dict()...
    dict.key = list.key
    assert dict.new_value = dict.prev_value + list.value
    return(build_dict(list=list+KeyValue.SIZE,size=size-KeyValue.SIZE,dict=dict+DictAccess.SIZE))
end

# Verifies that the initial values were 0, and writes the final
# values to result.
func verify_and_output_squashed_dict(
    squashed_dict : DictAccess*,
    squashed_dict_end : DictAccess*,
    result : KeyValue*,
) -> (result):
    tempvar diff = squashed_dict_end - squashed_dict
    if diff == 0:
        return (result=result)
    end
    assert squashed_dict_end.prev_value = 0
    result.key = squashed_dict_end.key
    result.value = squashed_dict_end.new_value
    return(verify_and_output_squashed_dict(squashed_dict=squashed_dict,squashed_dict_end+DictAccess.SIZE,result=result+KeyValue.SIZE))
    # Verify prev_value is 0...
    # Copy key to result.key...
    # Copy new_value to result.value...
    # Call recursively to verify_and_output_squashed_dict...
end

# Given a list of KeyValue, sums the values, grouped by key,
# and returns a list of pairs (key, sum_of_values).
func sum_by_key{range_check_ptr}(list : KeyValue*, size) -> (
    result, result_size
):

    alloc_locals
    let (local size) = alloc()
    let (local dict_start : DictAccess*) = alloc()
    let (local squashed_dict : DictAccess*) = alloc()
    let (local result : KeyValue*) = alloc()

    %{
        # Initialize cumulative_sums with an empty dictionary.
        # This variable will be used by ``build_dict`` to hold
        # the current sum for each key.
        cumulative_sums = {}
    
    %}
    #local memory ayırma olayı tam çalışmıyo olabilir burda
   

    let (dict_end) = build_dict(list=list,size=size,dict=dict_start)
    #neden squashed_dict_end için pointer türünü verirken dict_end için vermedik
    let (squashed_dict_end : DictAccess*) = squash_dict(
        dict_accesses=dict_start,
        dict_accesses_end=dict_end,
        squashed_dict=squashed_dict,
    )
    #pointer gerekebilir sanki
    let last_result = verify_and_output_squashed_dict(squashed_dict=squashed_dict,squashed_dict_end=squashed_dict_end,result=result)
    serialize_word(last_result)
    # Allocate memory for dict, squashed_dict and res...
    # Call build_dict()...
    # Call squash_dict()...
    # Call verify_and_output_squashed_dict()...
end

#Expected expression of type 'felt', got 'starkware.cairo.common.dict_access.DictAccess*'.
#        return (dict=dict)
#                    ^**^



