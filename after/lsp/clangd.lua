-- Ask clangd to attach the owning #include as an additional edit to completion
-- items. blink.cmp applies that edit when the completion is accepted, so using
-- a symbol from a header inserts the corresponding include automatically.
return {
  cmd = { "clangd", "--header-insertion=iwyu" },
}
