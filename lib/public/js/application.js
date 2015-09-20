var api = $.api = {
    $reports: $('tbody#seo-reports'),

    $form: $('form#seo-analyzer-form'),

    utils: {
        removeErrorsFrom: function($element) {
            $element.find('.has-error').removeClass('has-error');
            $element.find('span.help-block').remove();
        }
    },

    callbacks: {
        // Actual form submit
        submit: function(event) {
            event.preventDefault(); // Don't submit form right away

            $this = $(this);

            $.ajax({
                url:  $this.attr('action'),
                method: $this.attr('method'),
                data: $this.serialize(),
                dataType: 'json'
            }).done(api.callbacks.submitSuccess).fail(api.callbacks.submitError);
        },

        submitSuccess: function(data) {
            api.$reports.append(data.report);
        },

        submitError: function(data) {
            var errors = data.responseJSON.errors;

            $.each(errors, function(error, errorDescription) {
                alert(error + ":" + errorDescription);
            });
        }
    }
};


// Events
api.$form.bind('submit', api.callbacks.submit)
