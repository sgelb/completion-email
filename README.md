# completion-email

Mail sender and recipients completion source for
[nvim-cmp](https://github.com/hrsh7th/nvim-cmp). Very much adapted to my
setup with msmtp, notmuch and Neomutt.

Email addresses for `From:` are extracted from `.msmtprc`. Recipient addresses
for `To:`, `Cc:`, `Bcc:` and `Reply-To:` are extracted using `notmuch`.


Based on https://github.com/cbarrete/completion-vcard.

## Usage

For `nvim-cmp`:

```lua
require('cmp').setup({
    -- ...
    sources = {
        { name = 'email' },
        -- ...
    },
})

require('cmp').register_source('email', require('completion_email').setup_cmp('~/path/to/.msmtprc'))
```
