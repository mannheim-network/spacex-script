
const Joi = require('joi')
const { chainSchema } = require('./chain.schema')
const { apiSchema } = require('./api.schema')
const { identitySchema } = require('./identity.schema')
const { nodeSchema } = require('./node.schema')

function getConfigSchema(config) {
  let sMap = {
    node: nodeSchema.required(),
    chain: chainSchema.required(),
  }

  if (config.node.storage == "enable") {
    sMap["api"] = apiSchema.required()
    sMap["identity"] = identitySchema.required()
    sMap["storage"] = Joi.object().default()
  }

  if (config.node.sfrontend != "disable") {
    sMap["identity"] = identitySchema.required()
    sMap["sfrontend"] = Joi.object().default()
  }

  if (config.node.ipfs == "enable") {
    sMap["ipfs"] = Joi.object().default()
  }

  return Joi.object(sMap)
}

module.exports = {
  getConfigSchema,
}
