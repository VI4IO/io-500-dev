all:
	mkdir -p io500 results
	cp *.sh ior mdtest md-real-io io500
	cd io500
	#sbatch startup.sh
	./startup.sh

clean:
	#rm -rf io500 results
	rm -rf find_subtree.cfg 10.txt io_500_out* io_500_err*
