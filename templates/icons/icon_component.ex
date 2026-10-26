  @doc """
  Renders a [Lucide](https://lucide.dev/icons) icon.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/lucide/icons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/lucide.js`.

  In dev and test, unknown icon names raise an error instead of rendering nothing.

  ## Examples

      <.icon name="lucide-x" />
      <.icon name="lucide-refresh-cw" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: "size-4"

  def icon(%{name: "lucide-" <> icon} = assigns) do
    validate_icon!(icon)

    ~H"""
    <span class={[@name, @class]} />
    """
  end

  def icon(%{name: name}) do
    raise ArgumentError, "icon names must start with \"lucide-\", got: #{inspect(name)}"
  end

  # dev/test only: fail loudly on unknown icons instead of rendering nothing
  if Application.compile_env(:__APP__, :validate_icons, false) do
    # with the `sparse: "icons"` option, the dependency path is already deps/lucide/icons
    @lucide_icons Mix.Project.deps_paths()[:lucide]

    defp validate_icon!(icon) do
      unless File.exists?(Path.join(@lucide_icons, icon <> ".svg")) do
        raise ArgumentError,
              "unknown Lucide icon #{inspect(icon)}; see deps/lucide/icons or https://lucide.dev/icons"
      end
    end
  else
    defp validate_icon!(_icon), do: :ok
  end
