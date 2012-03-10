module Utils::ArchitectureList
  def universal?
    self.include? :i386 and self.include? :x86_64
  end

  def remove_ppc!
    self.delete :ppc7400
    self.delete :ppc64
  end

  def as_arch_flags
    self.collect{ |a| "-arch #{a}" }.join(' ')
  end
end
