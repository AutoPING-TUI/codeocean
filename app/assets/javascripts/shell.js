$(document).on('turbolinks:load', function () {
    const ENTER_KEY_CODE = 13;

    const clearOutput = function () {
        $('#output').html('');
    };

    const executeCommand = function (command) {
        $.ajax({
            data: {
                command: command
            },
            method: 'POST',
            url: $('#shell').data('url')
        }).done(handleResponse);
    };

    const handleKeyPress = function (event) {
        if (event.which === ENTER_KEY_CODE) {
            const command = $(this).val();
            if (command === 'clear') {
                clearOutput();
            } else {
                printCommand(command);
                executeCommand(command);
            }
            $(this).val('');
        }
    };

    const handleResponse = function (response) {
        if (response.status === 'timeout') {
            printTimeout(response);
        } else {
            printOutput(response);
        }
    };

    const printCommand = function (command) {
        const em = $('<em>');
        em.text(command);
        const p = $('<p>');
        p.append(em)
        $('#output').append(p);
    };

    const printOutput = function (output) {
        if (output) {
            if (output.stdout) {
                const element = $('<p>');
                element.addClass('text-success');
                element.text(output.stdout);
                $('#output').append(element);
            }

            if (output.stderr) {
                const element = $('<p>');
                element.addClass('text-warning');
                element.text(output.stderr);
                $('#output').append(element);
            }

            if (!output.stdout && !output.stderr) {
                const element = $('<p>');
                element.addClass('text-muted');
                const output = $('#output');
                element.text(output.data('message-no-output'));
                output.append(element);
            }
        }
    };

    const printTimeout = function (output) {
        const element = $.append('<p>');
        element.addClass('text-danger');
        element.text($('#shell').data('message-timeout'));
        $('#output').append(element);
    };

    if ($('#shell').isPresent()) {
        const command = $('#command')
        command.focus();
        command.on('keypress', handleKeyPress);
    }
})
;
