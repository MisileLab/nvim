local M = {}

local function compact(text)
  return (text:gsub("%s+", ""))
end

local function find_descendant(node, wanted)
  if node:type() == wanted then
    return node
  end
  for child in node:iter_children() do
    local found = find_descendant(child, wanted)
    if found then
      return found
    end
  end
end

local function has_descendant(node, wanted)
  return find_descendant(node, wanted) ~= nil
end

local function declarator_name(node)
  local nested = node:field("declarator")[1]
  if nested then
    return declarator_name(nested)
  end
  if node:type() == "identifier" or node:type() == "field_identifier" or node:type() == "qualified_identifier" then
    return node
  end
  for child in node:iter_children() do
    local found = declarator_name(child)
    if found then
      return found
    end
  end
end

local function namespace_prefix(node, bufnr)
  local names = {}
  local parent = node:parent()
  while parent do
    if parent:type() == "namespace_definition" then
      local name = parent:field("name")[1]
      if name then
        table.insert(names, 1, vim.treesitter.get_node_text(name, bufnr))
      end
    end
    parent = parent:parent()
  end
  return #names > 0 and table.concat(names, "::") .. "::" or ""
end

local function is_free_function(node)
  local parent = node:parent()
  while parent do
    local kind = parent:type()
    if kind == "class_specifier" or kind == "struct_specifier" or kind == "union_specifier" then
      return false
    end
    -- Function templates must remain visible to their callers, so generating
    -- their definitions in a .cpp file would be incorrect.
    if kind == "template_declaration" then
      return false
    end
    parent = parent:parent()
  end
  return true
end

local function relative_offset(bufnr, container, target_row, target_col)
  local start_row, start_col = container:range()
  if target_row == start_row then
    return target_col - start_col
  end

  local first = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1] or ""
  local offset = #first - start_col + 1
  for row = start_row + 1, target_row - 1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
    offset = offset + #line + 1
  end
  return offset + target_col
end

local function remove_node_range(text, bufnr, container, first, last)
  local start_row, start_col = first:range()
  local _, _, end_row, end_col = last:range()
  local start_offset = relative_offset(bufnr, container, start_row, start_col)
  local end_offset = relative_offset(bufnr, container, end_row, end_col)
  return text:sub(1, start_offset) .. text:sub(end_offset + 1)
end

local function remove_default_value(text, bufnr, container, parameter)
  local declarator = parameter:field("declarator")[1]
  local default = parameter:field("default_value")[1]
  if not declarator or not default then
    return text
  end

  local _, _, start_row, start_col = declarator:range()
  local _, _, end_row, end_col = default:range()
  local start_offset = relative_offset(bufnr, container, start_row, start_col)
  local end_offset = relative_offset(bufnr, container, end_row, end_col)
  return text:sub(1, start_offset) .. text:sub(end_offset + 1)
end

local function parameter_key(parameter, bufnr)
  local text = vim.treesitter.get_node_text(parameter, bufnr)
  local default = parameter:field("default_value")[1]
  if default then
    text = remove_default_value(text, bufnr, parameter, parameter)
  end

  local declarator = parameter:field("declarator")[1]
  local name = declarator and declarator_name(declarator)
  if name then
    text = remove_node_range(text, bufnr, parameter, name, name)
  end
  return compact(text)
end

local function function_parts(function_declarator, bufnr)
  local name_node = declarator_name(function_declarator:field("declarator")[1])
  local parameters = function_declarator:field("parameters")[1]
  if not name_node or not parameters then
    return nil
  end

  local name = vim.treesitter.get_node_text(name_node, bufnr)
  if not name:find("::", 1, true) then
    name = namespace_prefix(function_declarator, bufnr) .. name
  end

  local parameter_types = {}
  local parameter_names = {}
  for child in parameters:iter_children() do
    if child:named() then
      table.insert(parameter_types, parameter_key(child, bufnr))
      local declarator = child:field("declarator")[1]
      local parameter_name = declarator and declarator_name(declarator)
      table.insert(parameter_names, parameter_name and vim.treesitter.get_node_text(parameter_name, bufnr) or false)
    end
  end
  name = compact(name)
  return {
    key = name .. "(" .. table.concat(parameter_types, ",") .. ")",
    name = name,
    parameter_names = parameter_names,
    parameter_types = parameter_types,
  }
end

local function visit(node, callback)
  callback(node)
  for child in node:iter_children() do
    visit(child, callback)
  end
end

local function existing_definitions(bufnr)
  local parser = vim.treesitter.get_parser(bufnr, "cpp")
  local root = parser:parse()[1]:root()
  local definitions = { by_key = {}, by_name = {} }
  visit(root, function(node)
    if node:type() == "function_definition" then
      local declarator = find_descendant(node:field("declarator")[1], "function_declarator")
      local parts = declarator and function_parts(declarator, bufnr)
      if parts then
        local entry = {
          definition = node,
          function_declarator = declarator,
          name = parts.name,
          parameter_names = parts.parameter_names,
          parameter_types = parts.parameter_types,
          outer_declarator = node:field("declarator")[1],
        }
        definitions.by_key[parts.key] = entry
        definitions.by_name[parts.name] = definitions.by_name[parts.name] or {}
        table.insert(definitions.by_name[parts.name], entry)
      end
    end
  end)
  return definitions
end

local function definition_text(declaration, function_declarator, bufnr, qualify_namespace)
  local text = vim.treesitter.get_node_text(declaration, bufnr):gsub("%s*;%s*$", "")

  local optional_parameters = {}
  visit(function_declarator, function(node)
    if node:type() == "optional_parameter_declaration" then
      table.insert(optional_parameters, node)
    end
  end)
  table.sort(optional_parameters, function(a, b)
    local a_row, a_col = a:range()
    local b_row, b_col = b:range()
    return a_row > b_row or (a_row == b_row and a_col > b_col)
  end)
  for _, parameter in ipairs(optional_parameters) do
    text = remove_default_value(text, bufnr, declaration, parameter)
  end

  local name_node = declarator_name(function_declarator:field("declarator")[1])
  local name = name_node and vim.treesitter.get_node_text(name_node, bufnr)
  local prefix = qualify_namespace == false and "" or namespace_prefix(function_declarator, bufnr)
  if name and prefix ~= "" and not name:find("::", 1, true) then
    local start_row, start_col, end_row, end_col = name_node:range()
    local start_offset = relative_offset(bufnr, declaration, start_row, start_col)
    local end_offset = relative_offset(bufnr, declaration, end_row, end_col)
    text = text:sub(1, start_offset) .. prefix .. name .. text:sub(end_offset + 1)
  end

  return { "", text, "{", "}" }
end

local function string_offset(text, target_row, target_col)
  local lines = vim.split(text, "\n", { plain = true })
  local offset = 0
  for row = 1, target_row do
    offset = offset + #(lines[row] or "") + 1
  end
  return offset + target_col
end

local function preserve_parameter_names(signature, source_names)
  local parsed = signature .. "\n{}"
  local parser = vim.treesitter.get_string_parser(parsed, "cpp")
  local root = parser:parse()[1]:root()
  local definition = find_descendant(root, "function_definition")
  local function_declarator = definition
    and find_descendant(definition:field("declarator")[1], "function_declarator")
  local parameters = function_declarator and function_declarator:field("parameters")[1]
  if not parameters then
    return signature
  end

  local edits = {}
  local index = 0
  for parameter in parameters:iter_children() do
    if parameter:named() then
      index = index + 1
      local declarator = parameter:field("declarator")[1]
      local name = declarator and declarator_name(declarator)
      local replacement = source_names[index]
      if name and replacement then
        local start_row, start_col, end_row, end_col = name:range()
        table.insert(edits, {
          start_offset = string_offset(parsed, start_row, start_col),
          end_offset = string_offset(parsed, end_row, end_col),
          replacement = replacement,
        })
      end
    end
  end

  table.sort(edits, function(a, b)
    return a.start_offset > b.start_offset
  end)
  for _, edit in ipairs(edits) do
    parsed = parsed:sub(1, edit.start_offset) .. edit.replacement .. parsed:sub(edit.end_offset + 1)
  end
  return (parsed:gsub("\n{}$", ""))
end

local function parameter_distance(left, right)
  local score = math.abs(#left - #right) * 10
  for index = 1, math.min(#left, #right) do
    if left[index] ~= right[index] then
      score = score + 1
    end
  end
  return score
end

function M.add_free_functions(header_buf, implementation)
  local source_buf = vim.fn.bufadd(implementation)
  vim.fn.bufload(source_buf)
  local definitions = existing_definitions(source_buf)
  local parser = vim.treesitter.get_parser(header_buf, "cpp")
  local root = parser:parse()[1]:root()
  local output = {}
  local signature_edits = {}
  local declarations = {}

  visit(root, function(node)
    if node:type() ~= "declaration" or not is_free_function(node) then
      return
    end
    local outer = node:field("declarator")[1]
    local function_declarator = outer and find_descendant(outer, "function_declarator")
    if not function_declarator then
      return
    end

    -- `int (*callback)(int)` declares a function-pointer variable, not a
    -- function. A real function's name declarator is not itself a pointer.
    local name_declarator = function_declarator:field("declarator")[1]
    if name_declarator and has_descendant(name_declarator, "pointer_declarator") then
      return
    end

    local parts = function_parts(function_declarator, header_buf)
    if parts then
      table.insert(declarations, {
        declaration = node,
        function_declarator = function_declarator,
        outer_declarator = outer,
        key = parts.key,
        name = parts.name,
        parameter_types = parts.parameter_types,
      })
    end
  end)

  -- Reserve exact overload matches first. This prevents a newly added or
  -- reordered overload from stealing the body of an unchanged definition.
  local claimed = {}
  for _, declaration in ipairs(declarations) do
    local exact = definitions.by_key[declaration.key]
    if exact then
      declaration.existing = exact
      claimed[exact] = true
    end
  end

  -- For changed argument lists, pair the declaration with the closest
  -- remaining definition of the same name. Ties are left unmatched and get a
  -- fresh stub instead of risking the wrong overload's body.
  for _, declaration in ipairs(declarations) do
    if not declaration.existing then
      local best
      local best_score
      local tied = false
      for _, candidate in ipairs(definitions.by_name[declaration.name] or {}) do
        if not claimed[candidate] then
          local score = parameter_distance(declaration.parameter_types, candidate.parameter_types)
          if best_score == nil or score < best_score then
            best = candidate
            best_score = score
            tied = false
          elseif score == best_score then
            tied = true
          end
        end
      end
      if best and not tied then
        declaration.existing = best
        claimed[best] = true
      end
    end
  end

  for _, declaration in ipairs(declarations) do
    local existing = declaration.existing
    if not existing then
      vim.list_extend(
        output,
        definition_text(declaration.declaration, declaration.function_declarator, header_buf)
      )
    else
      local qualify_namespace = namespace_prefix(existing.function_declarator, source_buf) == ""
      local signature = definition_text(
        declaration.declaration,
        declaration.function_declarator,
        header_buf,
        qualify_namespace
      )[2]
      signature = preserve_parameter_names(signature, existing.parameter_names)

      local body = existing.definition:field("body")[1]
      local start_row, start_col = existing.definition:range()
      local end_row, end_col = body:range()
      local current = vim.api.nvim_buf_get_text(source_buf, start_row, start_col, end_row, end_col, {})
      if compact(table.concat(current, "\n")) ~= compact(signature) then
        table.insert(signature_edits, {
          start_row = start_row,
          start_col = start_col,
          end_row = end_row,
          end_col = end_col,
          text = signature .. "\n",
        })
      end
    end
  end

  table.sort(signature_edits, function(a, b)
    return a.start_row > b.start_row or (a.start_row == b.start_row and a.start_col > b.start_col)
  end)
  for _, edit in ipairs(signature_edits) do
    vim.api.nvim_buf_set_text(
      source_buf,
      edit.start_row,
      edit.start_col,
      edit.end_row,
      edit.end_col,
      vim.split(edit.text, "\n", { plain = true })
    )
  end

  if #output > 0 then
    vim.api.nvim_buf_set_lines(source_buf, -1, -1, false, output)
  end
  if #signature_edits > 0 or #output > 0 then
    vim.api.nvim_buf_call(source_buf, function()
      vim.cmd("noautocmd write")
    end)
  end
end

return M
