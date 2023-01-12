window.addEventListener('turbolinks:load', () => {
  const select2Config = {
    theme: 'bootstrap-5',
    tags: true,
    createTag: (params) => {
      // probably don't need jquery here
      var term = $.trim(params.term);
  
      if (term === '') {
        return null;
      }
  
      return {
        id: term,
        text: term,
        newTag: true
      }
    }
  };

  $('.ingredient-select').select2(select2Config);
});