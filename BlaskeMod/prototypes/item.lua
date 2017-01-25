data:extend(
{
  {
    type = "mining-tool",
    name = "steel-shovel",
    icon = "__BlaskeMod__/graphics/icons/steel-shovel.png",
    flags = {"goes-to-main-inventory"},
    action =
    {
      type="direct",
      action_delivery =
      {
        type = "instant",
        target_effects =
        {
            type = "damage",
            damage = { amount = 1 , type = "physical"}
        }
      }
    },
    durability = 10000,
    subgroup = "tool",
    order = "a[mining]-b[steel-shovel]",
    speed = 3,
    stack_size = 1
  }
}
)
