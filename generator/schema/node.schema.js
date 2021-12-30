const Joi = require('joi')

const nodeSchema = Joi.object({
  chain: Joi.string().valid('authority', 'full').required(),
  storage: Joi.string().valid('enable', 'disable').required(),
  sfrontend: Joi.string().valid('disable', 'isolation', 'member').required(),
  ipfs: Joi.string().valid('enable', 'disable').required(),
})

module.exports = {
  nodeSchema,
}